import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sync_config.dart';
import '../models/file_metadata.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'drive_sync.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sync_configs (
        id TEXT PRIMARY KEY,
        driveFolderId TEXT NOT NULL,
        driveFolderName TEXT NOT NULL,
        localFolderPath TEXT NOT NULL,
        isEnabled INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        lastSyncedAt INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE file_metadata (
        id TEXT PRIMARY KEY,
        driveFileId TEXT NOT NULL,
        localPath TEXT NOT NULL,
        fileName TEXT NOT NULL,
        fileSize INTEGER NOT NULL,
        modifiedTime INTEGER NOT NULL,
        localModifiedTime INTEGER,
        syncStatus INTEGER NOT NULL,
        isFavorite INTEGER NOT NULL,
        mimeType TEXT,
        md5Checksum TEXT,
        syncConfigId TEXT NOT NULL,
        errorMessage TEXT,
        FOREIGN KEY (syncConfigId) REFERENCES sync_configs (id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_config ON file_metadata(syncConfigId)
    ''');
  }

  Future<void> insertSyncConfig(SyncConfig config) async {
    final db = await database;
    await db.insert(
      'sync_configs',
      config.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SyncConfig>> getAllSyncConfigs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sync_configs');
    return List.generate(maps.length, (i) => SyncConfig.fromJson(maps[i]));
  }

  Future<void> updateSyncConfig(SyncConfig config) async {
    final db = await database;
    await db.update(
      'sync_configs',
      config.toJson(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
  }

  Future<void> deleteSyncConfig(String id) async {
    final db = await database;
    await db.delete('sync_configs', where: 'id = ?', whereArgs: [id]);
    await db.delete(
      'file_metadata',
      where: 'syncConfigId = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertFileMetadata(FileMetadata metadata) async {
    final db = await database;
    await db.insert(
      'file_metadata',
      metadata.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FileMetadata>> getFileMetadataForConfig(String configId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'file_metadata',
      where: 'syncConfigId = ?',
      whereArgs: [configId],
    );
    return List.generate(maps.length, (i) => FileMetadata.fromJson(maps[i]));
  }

  Future<FileMetadata?> getFileMetadataByDriveId(String driveFileId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'file_metadata',
      where: 'driveFileId = ?',
      whereArgs: [driveFileId],
    );
    if (maps.isEmpty) return null;
    return FileMetadata.fromJson(maps.first);
  }

  Future<void> updateFileMetadata(FileMetadata metadata) async {
    final db = await database;
    await db.update(
      'file_metadata',
      metadata.toJson(),
      where: 'id = ?',
      whereArgs: [metadata.id],
    );
  }

  Future<void> deleteFileMetadata(String id) async {
    final db = await database;
    await db.delete('file_metadata', where: 'id = ?', whereArgs: [id]);
  }
}
