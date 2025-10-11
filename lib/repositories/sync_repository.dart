import '../models/sync_config.dart';
import '../models/file_metadata.dart';
import '../models/sync_state.dart';
import '../services/google_drive_service.dart';
import '../services/local_file_service.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

class SyncRepository {
  final GoogleDriveService _driveService;
  final LocalFileService _localService;
  final DatabaseService _dbService;
  late final SyncService _syncService;

  SyncRepository(this._driveService, this._localService, this._dbService) {
    _syncService = SyncService(_driveService, _localService, _dbService);
  }

  Future<List<SyncConfig>> getAllSyncConfigs() async {
    return await _dbService.getAllSyncConfigs();
  }

  Future<void> addSyncConfig(SyncConfig config) async {
    await _dbService.insertSyncConfig(config);
  }

  Future<void> updateSyncConfig(SyncConfig config) async {
    await _dbService.updateSyncConfig(config);
  }

  Future<void> deleteSyncConfig(String configId) async {
    await _dbService.deleteSyncConfig(configId);
    // Also delete local files
    final syncDir = await _localService.getSyncDirectory(configId);
    await _localService.deleteDirectory(syncDir);
  }

  Future<List<FileMetadata>> getFilesForConfig(String configId) async {
    return await _dbService.getFileMetadataForConfig(configId);
  }

  Stream<SyncState> syncFolder(SyncConfig config) {
    return _syncService.syncFolder(config);
  }

  Future<List<DriveFile>> searchDriveFolders() async {
    return await _driveService.searchFolders();
  }

  Future<int> getStorageUsed() async {
    final basePath = await _localService.getAppDocumentsPath();
    return await _localService.getDirectorySize(basePath);
  }

  Future<void> clearCache() async {
    final basePath = await _localService.getAppDocumentsPath();
    await _localService.deleteDirectory(basePath);
    await _localService.createDirectory(basePath);
  }

  void setConflictResolution(ConflictResolution resolution) {
    _syncService.conflictResolution = resolution;
  }
}
