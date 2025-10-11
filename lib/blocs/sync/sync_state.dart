import 'package:equatable/equatable.dart';
import '../../models/sync_config.dart';
import '../../models/sync_state.dart' as model;

enum SyncBlocStatus { initial, loading, loaded, syncing, error }

class SyncBlocState extends Equatable {
  final SyncBlocStatus status;
  final List<SyncConfig> configs;
  final model.SyncState? currentSyncState;
  final String? errorMessage;

  const SyncBlocState({
    required this.status,
    this.configs = const [],
    this.currentSyncState,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, configs, currentSyncState, errorMessage];

  SyncBlocState copyWith({
    SyncBlocStatus? status,
    List<SyncConfig>? configs,
    model.SyncState? currentSyncState,
    String? errorMessage,
  }) {
    return SyncBlocState(
      status: status ?? this.status,
      configs: configs ?? this.configs,
      currentSyncState: currentSyncState ?? this.currentSyncState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static const initial = SyncBlocState(status: SyncBlocStatus.initial);
}
