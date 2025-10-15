import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
// dart:typed_data import is unnecessary; Flutter services exports Uint8List
import 'dart:convert';

class LocalFile {
  final String path;
  final String name;
  final int size;
  final DateTime modifiedTime;
  final bool isDirectory;

  LocalFile({
    required this.path,
    required this.name,
    required this.size,
    required this.modifiedTime,
    required this.isDirectory,
  });
}

class LocalFileService {
  static const MethodChannel _bookmarkChannel = MethodChannel(
    'drive_sync/bookmarks',
  );
  Future<String> getAppDocumentsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<Map<String, String>?> pickLocalDirectory() async {
    String? directoryPath;
    try {
      directoryPath = await getDirectoryPath();
    } catch (_) {
      // Fallback to direct method channel if federated plugin isn't registered
      try {
        final MethodChannel fs = const MethodChannel(
          'plugins.flutter.io/file_selector',
        );
        directoryPath = await fs.invokeMethod<String>('getDirectoryPath');
      } catch (_) {}
    }
    if (directoryPath == null) return null;
    try {
      // Create security-scoped bookmark on iOS
      if (Platform.isIOS) {
        final bookmarkBytes =
            await _bookmarkChannel.invokeMethod('createBookmark', {
                  'url': 'file://$directoryPath',
                })
                as Uint8List;
        final startedPath =
            await _bookmarkChannel.invokeMethod('startAccess', {
                  'bookmark': bookmarkBytes,
                })
                as String;
        return {
          'path': startedPath,
          'bookmark': base64Encode(bookmarkBytes),
          'displayName': path.basename(directoryPath),
        };
      }
    } catch (_) {
      // Fall back to path only
    }
    return {'path': directoryPath, 'displayName': path.basename(directoryPath)};
  }

  Future<void> startAccessIfNeeded(String? bookmarkBase64) async {
    if (!Platform.isIOS) return;
    if (bookmarkBase64 == null) return;
    try {
      final MethodChannel ch = const MethodChannel('drive_sync/bookmarks');
      final bytes = Uint8List.fromList(base64.decode(bookmarkBase64));
      await ch.invokeMethod('startAccess', {'bookmark': bytes});
    } catch (_) {}
  }

  Future<void> stopAccessIfNeeded() async {
    if (!Platform.isIOS) return;
    try {
      final MethodChannel ch = const MethodChannel('drive_sync/bookmarks');
      await ch.invokeMethod('stopAccess');
    } catch (_) {}
  }

  Future<String> getSyncDirectory(String syncConfigId) async {
    final basePath = await getAppDocumentsPath();
    final syncPath = path.join(basePath, 'synced_folders', syncConfigId);
    await Directory(syncPath).create(recursive: true);
    return syncPath;
  }

  Future<List<LocalFile>> listFilesInDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) return [];

    final List<LocalFile> files = [];
    await for (final entity in directory.list()) {
      final stat = await entity.stat();
      files.add(
        LocalFile(
          path: entity.path,
          name: path.basename(entity.path),
          size: stat.size,
          modifiedTime: stat.modified,
          isDirectory: entity is Directory,
        ),
      );
    }

    return files;
  }

  Future<List<LocalFile>> listAllFilesRecursively(String directoryPath) async {
    final List<LocalFile> allFiles = [];
    final directory = Directory(directoryPath);

    if (!await directory.exists()) return [];

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final stat = await entity.stat();
        allFiles.add(
          LocalFile(
            path: entity.path,
            name: path.basename(entity.path),
            size: stat.size,
            modifiedTime: stat.modified,
            isDirectory: false,
          ),
        );
      }
    }

    return allFiles;
  }

  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> createDirectory(String directoryPath) async {
    await Directory(directoryPath).create(recursive: true);
  }

  Future<String> getRelativePath(String fullPath, String basePath) async {
    return path.relative(fullPath, from: basePath);
  }

  Future<int> getDirectorySize(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) return 0;

    int totalSize = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final stat = await entity.stat();
        totalSize += stat.size;
      }
    }

    return totalSize;
  }

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
