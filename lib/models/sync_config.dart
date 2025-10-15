import 'package:equatable/equatable.dart';

class SyncConfig extends Equatable {
  final String id;
  final String driveFolderId;
  final String driveFolderName;
  final String localFolderPath;
  final String? localFolderBookmark; // iOS: security-scoped bookmark
  final String? localFolderDisplayName; // for UI convenience
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime? lastSyncedAt;

  const SyncConfig({
    required this.id,
    required this.driveFolderId,
    required this.driveFolderName,
    required this.localFolderPath,
    this.localFolderBookmark,
    this.localFolderDisplayName,
    this.isEnabled = true,
    required this.createdAt,
    this.lastSyncedAt,
  });

  @override
  List<Object?> get props => [
    id,
    driveFolderId,
    driveFolderName,
    localFolderPath,
    localFolderBookmark,
    localFolderDisplayName,
    isEnabled,
    createdAt,
    lastSyncedAt,
  ];

  SyncConfig copyWith({
    String? id,
    String? driveFolderId,
    String? driveFolderName,
    String? localFolderPath,
    String? localFolderBookmark,
    String? localFolderDisplayName,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? lastSyncedAt,
  }) {
    return SyncConfig(
      id: id ?? this.id,
      driveFolderId: driveFolderId ?? this.driveFolderId,
      driveFolderName: driveFolderName ?? this.driveFolderName,
      localFolderPath: localFolderPath ?? this.localFolderPath,
      localFolderBookmark: localFolderBookmark ?? this.localFolderBookmark,
      localFolderDisplayName:
          localFolderDisplayName ?? this.localFolderDisplayName,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driveFolderId': driveFolderId,
      'driveFolderName': driveFolderName,
      'localFolderPath': localFolderPath,
      'localFolderBookmark': localFolderBookmark,
      'localFolderDisplayName': localFolderDisplayName,
      'isEnabled': isEnabled ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastSyncedAt': lastSyncedAt?.millisecondsSinceEpoch,
    };
  }

  factory SyncConfig.fromJson(Map<String, dynamic> json) {
    return SyncConfig(
      id: json['id'] as String,
      driveFolderId: json['driveFolderId'] as String,
      driveFolderName: json['driveFolderName'] as String,
      localFolderPath: json['localFolderPath'] as String,
      localFolderBookmark: json['localFolderBookmark'] as String?,
      localFolderDisplayName: json['localFolderDisplayName'] as String?,
      isEnabled: json['isEnabled'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastSyncedAt'] as int)
          : null,
    );
  }
}
