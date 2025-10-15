import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/sync_config.dart';
import '../models/file_metadata.dart';
import '../models/sync_state.dart';
import 'google_drive_service.dart';
import 'local_file_service.dart';
import 'database_service.dart';

enum ConflictResolution { driveWins, localWins, newerWins }

class SyncService {
  final GoogleDriveService _driveService;
  final LocalFileService _localService;
  final DatabaseService _dbService;

  ConflictResolution conflictResolution = ConflictResolution.newerWins;

  SyncService(this._driveService, this._localService, this._dbService);

  Stream<SyncState> syncFolder(SyncConfig config) async* {
    yield const SyncState(operation: SyncOperation.checking);

    try {
      // Ensure access to user-chosen directory on iOS
      await _localService.startAccessIfNeeded(config.localFolderBookmark);
      final syncDir = config.localFolderPath;
      final driveFiles = await _driveService.listAllFilesRecursively(
        config.driveFolderId,
      );

      final localFiles = await _localService.listAllFilesRecursively(syncDir);
      final totalFiles = driveFiles.length + localFiles.length;
      int processedFiles = 0;

      // Download new/updated files from Drive
      yield SyncState(
        operation: SyncOperation.downloading,
        totalFiles: totalFiles,
        processedFiles: processedFiles,
      );

      for (final driveFile in driveFiles) {
        if (driveFile.isFolder) continue;

        final metadata = await _dbService.getFileMetadataByDriveId(
          driveFile.id,
        );
        final localPath = path.join(syncDir, driveFile.name);

        if (metadata == null) {
          // New file, download it
          await _driveService.downloadFile(driveFile.id, localPath);
          await _saveFileMetadata(driveFile, localPath, config.id);
        } else if (driveFile.modifiedTime.isAfter(metadata.modifiedTime)) {
          // File updated on Drive
          await _handleConflict(driveFile, localPath, metadata);
        }

        processedFiles++;
        yield SyncState(
          operation: SyncOperation.downloading,
          totalFiles: totalFiles,
          processedFiles: processedFiles,
          currentFileName: driveFile.name,
        );
      }

      // Upload new/updated local files to Drive
      yield SyncState(
        operation: SyncOperation.uploading,
        totalFiles: totalFiles,
        processedFiles: processedFiles,
      );

      for (final localFile in localFiles) {
        if (localFile.isDirectory) continue;

        final relativePath = await _localService.getRelativePath(
          localFile.path,
          syncDir,
        );

        final existingMetadata = await _findMetadataByLocalPath(
          relativePath,
          config.id,
        );

        if (existingMetadata == null) {
          // New local file, upload to Drive
          final fileId = await _driveService.uploadFile(
            localFile.path,
            localFile.name,
            config.driveFolderId,
          );

          final driveFile = await _driveService.getFileMetadata(fileId);
          if (driveFile != null) {
            await _saveFileMetadata(driveFile, localFile.path, config.id);
          }
        } else {
          final localModified = localFile.modifiedTime;
          if (localModified.isAfter(existingMetadata.modifiedTime)) {
            // Local file updated, upload to Drive
            await _driveService.updateFile(
              existingMetadata.driveFileId,
              localFile.path,
            );
            await _updateMetadataAfterUpload(existingMetadata, localModified);
          }
        }

        processedFiles++;
        yield SyncState(
          operation: SyncOperation.uploading,
          totalFiles: totalFiles,
          processedFiles: processedFiles,
          currentFileName: localFile.name,
        );
      }

      // Update sync config with last sync time
      await _dbService.updateSyncConfig(
        config.copyWith(lastSyncedAt: DateTime.now()),
      );

      yield SyncState(
        operation: SyncOperation.completed,
        totalFiles: totalFiles,
        processedFiles: processedFiles,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      yield SyncState(
        operation: SyncOperation.error,
        errorMessage: e.toString(),
      );
    } finally {
      await _localService.stopAccessIfNeeded();
    }
  }

  Future<void> _handleConflict(
    DriveFile driveFile,
    String localPath,
    FileMetadata metadata,
  ) async {
    final localFile = File(localPath);
    if (!await localFile.exists()) {
      // Local file doesn't exist, just download
      await _driveService.downloadFile(driveFile.id, localPath);
      await _updateMetadataAfterDownload(metadata, driveFile);
      return;
    }

    final localStat = await localFile.stat();
    final localModified = localStat.modified;

    switch (conflictResolution) {
      case ConflictResolution.driveWins:
        await _driveService.downloadFile(driveFile.id, localPath);
        await _updateMetadataAfterDownload(metadata, driveFile);
        break;
      case ConflictResolution.localWins:
        await _driveService.updateFile(metadata.driveFileId, localPath);
        await _updateMetadataAfterUpload(metadata, localModified);
        break;
      case ConflictResolution.newerWins:
        if (driveFile.modifiedTime.isAfter(localModified)) {
          await _driveService.downloadFile(driveFile.id, localPath);
          await _updateMetadataAfterDownload(metadata, driveFile);
        } else {
          await _driveService.updateFile(metadata.driveFileId, localPath);
          await _updateMetadataAfterUpload(metadata, localModified);
        }
        break;
    }
  }

  Future<void> _saveFileMetadata(
    DriveFile driveFile,
    String localPath,
    String syncConfigId,
  ) async {
    final metadata = FileMetadata(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      driveFileId: driveFile.id,
      localPath: localPath,
      fileName: driveFile.name,
      fileSize: driveFile.size,
      modifiedTime: driveFile.modifiedTime,
      syncStatus: SyncStatus.synced,
      isFavorite: driveFile.isStarred,
      mimeType: driveFile.mimeType,
      md5Checksum: driveFile.md5Checksum,
      syncConfigId: syncConfigId,
    );

    await _dbService.insertFileMetadata(metadata);
  }

  Future<void> _updateMetadataAfterDownload(
    FileMetadata metadata,
    DriveFile driveFile,
  ) async {
    final updated = metadata.copyWith(
      modifiedTime: driveFile.modifiedTime,
      fileSize: driveFile.size,
      md5Checksum: driveFile.md5Checksum,
      syncStatus: SyncStatus.synced,
      localModifiedTime: DateTime.now(),
    );
    await _dbService.updateFileMetadata(updated);
  }

  Future<void> _updateMetadataAfterUpload(
    FileMetadata metadata,
    DateTime localModified,
  ) async {
    final updated = metadata.copyWith(
      localModifiedTime: localModified,
      syncStatus: SyncStatus.synced,
    );
    await _dbService.updateFileMetadata(updated);
  }

  Future<FileMetadata?> _findMetadataByLocalPath(
    String relativePath,
    String configId,
  ) async {
    final allMetadata = await _dbService.getFileMetadataForConfig(configId);
    for (final metadata in allMetadata) {
      if (path.basename(metadata.localPath) == path.basename(relativePath)) {
        return metadata;
      }
    }
    return null;
  }
}
