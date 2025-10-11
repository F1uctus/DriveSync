import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';

class DriveFile {
  final String id;
  final String name;
  final int size;
  final DateTime modifiedTime;
  final bool isFolder;
  final String? mimeType;
  final String? md5Checksum;
  final bool isStarred;

  DriveFile({
    required this.id,
    required this.name,
    required this.size,
    required this.modifiedTime,
    required this.isFolder,
    this.mimeType,
    this.md5Checksum,
    this.isStarred = false,
  });

  factory DriveFile.fromDriveFile(drive.File file) {
    return DriveFile(
      id: file.id!,
      name: file.name!,
      size: file.size != null ? int.parse(file.size!) : 0,
      modifiedTime: file.modifiedTime!,
      isFolder: file.mimeType == 'application/vnd.google-apps.folder',
      mimeType: file.mimeType,
      md5Checksum: file.md5Checksum,
      isStarred: file.starred ?? false,
    );
  }
}

class GoogleDriveService {
  drive.DriveApi? _driveApi;

  Future<void> initialize(AuthClient authClient) async {
    _driveApi = drive.DriveApi(authClient);
  }

  bool get isInitialized => _driveApi != null;

  Future<List<DriveFile>> listFilesInFolder(String folderId) async {
    if (_driveApi == null) throw Exception('Drive API not initialized');

    final query = "'$folderId' in parents and trashed = false";
    final fileList = await _driveApi!.files.list(
      q: query,
      spaces: 'drive',
      $fields:
          'files(id, name, size, modifiedTime, mimeType, md5Checksum, starred)',
    );

    return fileList.files?.map((f) => DriveFile.fromDriveFile(f)).toList() ??
        [];
  }

  Future<List<DriveFile>> listAllFilesRecursively(String folderId) async {
    final List<DriveFile> allFiles = [];
    final queue = [folderId];

    while (queue.isNotEmpty) {
      final currentFolderId = queue.removeAt(0);
      final files = await listFilesInFolder(currentFolderId);

      for (final file in files) {
        allFiles.add(file);
        if (file.isFolder) {
          queue.add(file.id);
        }
      }
    }

    return allFiles;
  }

  Future<void> downloadFile(String fileId, String destinationPath) async {
    if (_driveApi == null) throw Exception('Drive API not initialized');

    final drive.Media? media =
        await _driveApi!.files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media?;

    if (media == null) throw Exception('Failed to download file');

    final file = File(destinationPath);
    await file.create(recursive: true);
    final sink = file.openWrite();

    await for (final chunk in media.stream) {
      sink.add(chunk);
    }

    await sink.close();
  }

  Future<String> uploadFile(
    String localPath,
    String fileName,
    String parentFolderId,
  ) async {
    if (_driveApi == null) throw Exception('Drive API not initialized');

    final file = File(localPath);
    final driveFile = drive.File()
      ..name = fileName
      ..parents = [parentFolderId];

    final media = drive.Media(file.openRead(), file.lengthSync());
    final uploadedFile = await _driveApi!.files.create(
      driveFile,
      uploadMedia: media,
    );

    return uploadedFile.id!;
  }

  Future<void> updateFile(String fileId, String localPath) async {
    if (_driveApi == null) throw Exception('Drive API not initialized');

    final file = File(localPath);
    final media = drive.Media(file.openRead(), file.lengthSync());

    await _driveApi!.files.update(drive.File(), fileId, uploadMedia: media);
  }

  Future<void> deleteFile(String fileId) async {
    if (_driveApi == null) throw Exception('Drive API not initialized');
    await _driveApi!.files.delete(fileId);
  }

  Future<String> createFolder(String folderName, String parentFolderId) async {
    if (_driveApi == null) throw Exception('Drive API not initialized');

    final folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder'
      ..parents = [parentFolderId];

    final createdFolder = await _driveApi!.files.create(folder);
    return createdFolder.id!;
  }

  Future<DriveFile?> getFileMetadata(String fileId) async {
    if (_driveApi == null) throw Exception('Drive API not initialized');

    final file =
        await _driveApi!.files.get(
              fileId,
              $fields:
                  'id, name, size, modifiedTime, mimeType, md5Checksum, starred',
            )
            as drive.File;

    return DriveFile.fromDriveFile(file);
  }

  Future<void> setFileFavorite(String fileId, bool starred) async {
    if (_driveApi == null) throw Exception('Drive API not initialized');

    await _driveApi!.files.update(drive.File()..starred = starred, fileId);
  }

  Future<List<DriveFile>> searchFolders() async {
    if (_driveApi == null) throw Exception('Drive API not initialized');

    final query =
        "mimeType='application/vnd.google-apps.folder' and trashed = false";
    final fileList = await _driveApi!.files.list(
      q: query,
      spaces: 'drive',
      $fields: 'files(id, name)',
    );

    return fileList.files?.map((f) => DriveFile.fromDriveFile(f)).toList() ??
        [];
  }
}
