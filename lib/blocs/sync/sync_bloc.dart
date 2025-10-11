import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/sync_repository.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncBlocState> {
  final SyncRepository _syncRepository;

  SyncBloc(this._syncRepository) : super(SyncBlocState.initial) {
    on<SyncLoadConfigs>(_onLoadConfigs);
    on<SyncAddConfig>(_onAddConfig);
    on<SyncDeleteConfig>(_onDeleteConfig);
    on<SyncStartManual>(_onStartManual);
  }

  Future<void> _onLoadConfigs(
    SyncLoadConfigs event,
    Emitter<SyncBlocState> emit,
  ) async {
    emit(state.copyWith(status: SyncBlocStatus.loading));

    try {
      final configs = await _syncRepository.getAllSyncConfigs();
      emit(state.copyWith(status: SyncBlocStatus.loaded, configs: configs));
    } catch (e) {
      emit(
        state.copyWith(
          status: SyncBlocStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onAddConfig(
    SyncAddConfig event,
    Emitter<SyncBlocState> emit,
  ) async {
    try {
      await _syncRepository.addSyncConfig(event.config);
      final configs = await _syncRepository.getAllSyncConfigs();
      emit(state.copyWith(status: SyncBlocStatus.loaded, configs: configs));
    } catch (e) {
      emit(
        state.copyWith(
          status: SyncBlocStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteConfig(
    SyncDeleteConfig event,
    Emitter<SyncBlocState> emit,
  ) async {
    try {
      await _syncRepository.deleteSyncConfig(event.configId);
      final configs = await _syncRepository.getAllSyncConfigs();
      emit(state.copyWith(status: SyncBlocStatus.loaded, configs: configs));
    } catch (e) {
      emit(
        state.copyWith(
          status: SyncBlocStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onStartManual(
    SyncStartManual event,
    Emitter<SyncBlocState> emit,
  ) async {
    emit(state.copyWith(status: SyncBlocStatus.syncing));

    await emit.forEach(
      _syncRepository.syncFolder(event.config),
      onData: (syncState) {
        return state.copyWith(
          status: SyncBlocStatus.syncing,
          currentSyncState: syncState,
        );
      },
      onError: (error, stackTrace) {
        return state.copyWith(
          status: SyncBlocStatus.error,
          errorMessage: error.toString(),
        );
      },
    );

    // After sync completes, reload configs to update last sync time
    final configs = await _syncRepository.getAllSyncConfigs();
    emit(state.copyWith(status: SyncBlocStatus.loaded, configs: configs));
  }
}
