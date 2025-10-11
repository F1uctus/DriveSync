import 'package:equatable/equatable.dart';
import '../../services/sync_service.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class SettingsLoad extends SettingsEvent {
  const SettingsLoad();
}

class SettingsUpdateSyncFrequency extends SettingsEvent {
  final Duration frequency;

  const SettingsUpdateSyncFrequency(this.frequency);

  @override
  List<Object?> get props => [frequency];
}

class SettingsUpdateConflictResolution extends SettingsEvent {
  final ConflictResolution resolution;

  const SettingsUpdateConflictResolution(this.resolution);

  @override
  List<Object?> get props => [resolution];
}

class SettingsToggleBackgroundSync extends SettingsEvent {
  final bool enabled;

  const SettingsToggleBackgroundSync(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class SettingsToggleCellularData extends SettingsEvent {
  final bool enabled;

  const SettingsToggleCellularData(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class SettingsLoadStorageInfo extends SettingsEvent {
  const SettingsLoadStorageInfo();
}

class SettingsClearCache extends SettingsEvent {
  const SettingsClearCache();
}
