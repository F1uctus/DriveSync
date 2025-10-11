import 'package:equatable/equatable.dart';
import '../../models/sync_config.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class SyncLoadConfigs extends SyncEvent {
  const SyncLoadConfigs();
}

class SyncAddConfig extends SyncEvent {
  final SyncConfig config;

  const SyncAddConfig(this.config);

  @override
  List<Object?> get props => [config];
}

class SyncDeleteConfig extends SyncEvent {
  final String configId;

  const SyncDeleteConfig(this.configId);

  @override
  List<Object?> get props => [configId];
}

class SyncStartManual extends SyncEvent {
  final SyncConfig config;

  const SyncStartManual(this.config);

  @override
  List<Object?> get props => [config];
}
