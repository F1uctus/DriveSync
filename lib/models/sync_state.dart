import 'package:equatable/equatable.dart';

enum SyncOperation { idle, checking, downloading, uploading, completed, error }

class SyncState extends Equatable {
  final SyncOperation operation;
  final int totalFiles;
  final int processedFiles;
  final String? currentFileName;
  final String? errorMessage;
  final DateTime? lastSyncTime;
  final bool isBackgroundSync;

  const SyncState({
    required this.operation,
    this.totalFiles = 0,
    this.processedFiles = 0,
    this.currentFileName,
    this.errorMessage,
    this.lastSyncTime,
    this.isBackgroundSync = false,
  });

  double get progress {
    if (totalFiles == 0) return 0.0;
    return processedFiles / totalFiles;
  }

  bool get isInProgress =>
      operation == SyncOperation.checking ||
      operation == SyncOperation.downloading ||
      operation == SyncOperation.uploading;

  @override
  List<Object?> get props => [
    operation,
    totalFiles,
    processedFiles,
    currentFileName,
    errorMessage,
    lastSyncTime,
    isBackgroundSync,
  ];

  SyncState copyWith({
    SyncOperation? operation,
    int? totalFiles,
    int? processedFiles,
    String? currentFileName,
    String? errorMessage,
    DateTime? lastSyncTime,
    bool? isBackgroundSync,
  }) {
    return SyncState(
      operation: operation ?? this.operation,
      totalFiles: totalFiles ?? this.totalFiles,
      processedFiles: processedFiles ?? this.processedFiles,
      currentFileName: currentFileName ?? this.currentFileName,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isBackgroundSync: isBackgroundSync ?? this.isBackgroundSync,
    );
  }

  static const initial = SyncState(operation: SyncOperation.idle);
}
