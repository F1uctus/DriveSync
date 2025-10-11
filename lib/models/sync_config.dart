import 'package:equatable/equatable.dart';

class SyncConfig extends Equatable {
  final String id;
  final String driveFolderId;
  final String driveFolderName;
  final String localFolderPath;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime? lastSyncedAt;

  const SyncConfig({
    required this.id,
    required this.driveFolderId,
    required this.driveFolderName,
    required this.localFolderPath,
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
    isEnabled,
    createdAt,
    lastSyncedAt,
  ];

  SyncConfig copyWith({
    String? id,
    String? driveFolderId,
    String? driveFolderName,
    String? localFolderPath,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? lastSyncedAt,
  }) {
    return SyncConfig(
      id: id ?? this.id,
      driveFolderId: driveFolderId ?? this.driveFolderId,
      driveFolderName: driveFolderName ?? this.driveFolderName,
      localFolderPath: localFolderPath ?? this.localFolderPath,
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
      isEnabled: json['isEnabled'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastSyncedAt'] as int)
          : null,
    );
  }
}
