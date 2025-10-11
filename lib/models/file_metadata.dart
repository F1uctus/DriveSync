import 'package:equatable/equatable.dart';

enum SyncStatus { synced, pending, syncing, conflict, error }

class FileMetadata extends Equatable {
  final String id;
  final String driveFileId;
  final String localPath;
  final String fileName;
  final int fileSize;
  final DateTime modifiedTime;
  final DateTime? localModifiedTime;
  final SyncStatus syncStatus;
  final bool isFavorite;
  final String? mimeType;
  final String? md5Checksum;
  final String syncConfigId;
  final String? errorMessage;

  const FileMetadata({
    required this.id,
    required this.driveFileId,
    required this.localPath,
    required this.fileName,
    required this.fileSize,
    required this.modifiedTime,
    this.localModifiedTime,
    required this.syncStatus,
    this.isFavorite = false,
    this.mimeType,
    this.md5Checksum,
    required this.syncConfigId,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
    id,
    driveFileId,
    localPath,
    fileName,
    fileSize,
    modifiedTime,
    localModifiedTime,
    syncStatus,
    isFavorite,
    mimeType,
    md5Checksum,
    syncConfigId,
    errorMessage,
  ];

  FileMetadata copyWith({
    String? id,
    String? driveFileId,
    String? localPath,
    String? fileName,
    int? fileSize,
    DateTime? modifiedTime,
    DateTime? localModifiedTime,
    SyncStatus? syncStatus,
    bool? isFavorite,
    String? mimeType,
    String? md5Checksum,
    String? syncConfigId,
    String? errorMessage,
  }) {
    return FileMetadata(
      id: id ?? this.id,
      driveFileId: driveFileId ?? this.driveFileId,
      localPath: localPath ?? this.localPath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      localModifiedTime: localModifiedTime ?? this.localModifiedTime,
      syncStatus: syncStatus ?? this.syncStatus,
      isFavorite: isFavorite ?? this.isFavorite,
      mimeType: mimeType ?? this.mimeType,
      md5Checksum: md5Checksum ?? this.md5Checksum,
      syncConfigId: syncConfigId ?? this.syncConfigId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driveFileId': driveFileId,
      'localPath': localPath,
      'fileName': fileName,
      'fileSize': fileSize,
      'modifiedTime': modifiedTime.millisecondsSinceEpoch,
      'localModifiedTime': localModifiedTime?.millisecondsSinceEpoch,
      'syncStatus': syncStatus.index,
      'isFavorite': isFavorite ? 1 : 0,
      'mimeType': mimeType,
      'md5Checksum': md5Checksum,
      'syncConfigId': syncConfigId,
      'errorMessage': errorMessage,
    };
  }

  factory FileMetadata.fromJson(Map<String, dynamic> json) {
    return FileMetadata(
      id: json['id'] as String,
      driveFileId: json['driveFileId'] as String,
      localPath: json['localPath'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      modifiedTime: DateTime.fromMillisecondsSinceEpoch(
        json['modifiedTime'] as int,
      ),
      localModifiedTime: json['localModifiedTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['localModifiedTime'] as int,
            )
          : null,
      syncStatus: SyncStatus.values[json['syncStatus'] as int],
      isFavorite: json['isFavorite'] == 1,
      mimeType: json['mimeType'] as String?,
      md5Checksum: json['md5Checksum'] as String?,
      syncConfigId: json['syncConfigId'] as String,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
