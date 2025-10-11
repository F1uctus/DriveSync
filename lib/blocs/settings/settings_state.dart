import 'package:equatable/equatable.dart';
import '../../services/sync_service.dart';

class SettingsState extends Equatable {
  final Duration syncFrequency;
  final ConflictResolution conflictResolution;
  final bool backgroundSyncEnabled;
  final bool cellularDataEnabled;
  final int storageUsed;
  final bool isLoading;

  const SettingsState({
    this.syncFrequency = const Duration(hours: 1),
    this.conflictResolution = ConflictResolution.newerWins,
    this.backgroundSyncEnabled = true,
    this.cellularDataEnabled = false,
    this.storageUsed = 0,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [
    syncFrequency,
    conflictResolution,
    backgroundSyncEnabled,
    cellularDataEnabled,
    storageUsed,
    isLoading,
  ];

  SettingsState copyWith({
    Duration? syncFrequency,
    ConflictResolution? conflictResolution,
    bool? backgroundSyncEnabled,
    bool? cellularDataEnabled,
    int? storageUsed,
    bool? isLoading,
  }) {
    return SettingsState(
      syncFrequency: syncFrequency ?? this.syncFrequency,
      conflictResolution: conflictResolution ?? this.conflictResolution,
      backgroundSyncEnabled:
          backgroundSyncEnabled ?? this.backgroundSyncEnabled,
      cellularDataEnabled: cellularDataEnabled ?? this.cellularDataEnabled,
      storageUsed: storageUsed ?? this.storageUsed,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
