import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/sync_repository.dart';
import '../../services/background_service.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  final SyncRepository _syncRepository;
  final BackgroundService _backgroundService;

  SettingsBloc(
    this._settingsRepository,
    this._syncRepository,
    this._backgroundService,
  ) : super(const SettingsState()) {
    on<SettingsLoad>(_onLoad);
    on<SettingsUpdateSyncFrequency>(_onUpdateSyncFrequency);
    on<SettingsUpdateConflictResolution>(_onUpdateConflictResolution);
    on<SettingsToggleBackgroundSync>(_onToggleBackgroundSync);
    on<SettingsToggleCellularData>(_onToggleCellularData);
    on<SettingsLoadStorageInfo>(_onLoadStorageInfo);
    on<SettingsClearCache>(_onClearCache);
  }

  Future<void> _onLoad(SettingsLoad event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true));

    final syncFrequency = await _settingsRepository.getSyncFrequency();
    final conflictResolution = await _settingsRepository
        .getConflictResolution();
    final backgroundSyncEnabled = await _settingsRepository
        .isBackgroundSyncEnabled();
    final cellularDataEnabled = await _settingsRepository
        .isCellularDataEnabled();
    final storageUsed = await _syncRepository.getStorageUsed();

    emit(
      state.copyWith(
        syncFrequency: syncFrequency,
        conflictResolution: conflictResolution,
        backgroundSyncEnabled: backgroundSyncEnabled,
        cellularDataEnabled: cellularDataEnabled,
        storageUsed: storageUsed,
        isLoading: false,
      ),
    );
  }

  Future<void> _onUpdateSyncFrequency(
    SettingsUpdateSyncFrequency event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.setSyncFrequency(event.frequency);
    emit(state.copyWith(syncFrequency: event.frequency));

    // Update background sync frequency
    if (state.backgroundSyncEnabled) {
      await _backgroundService.registerBackgroundSync(
        frequency: event.frequency,
      );
    }
  }

  Future<void> _onUpdateConflictResolution(
    SettingsUpdateConflictResolution event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.setConflictResolution(event.resolution);
    _syncRepository.setConflictResolution(event.resolution);
    emit(state.copyWith(conflictResolution: event.resolution));
  }

  Future<void> _onToggleBackgroundSync(
    SettingsToggleBackgroundSync event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.setBackgroundSyncEnabled(event.enabled);
    emit(state.copyWith(backgroundSyncEnabled: event.enabled));

    if (event.enabled) {
      await _backgroundService.registerBackgroundSync(
        frequency: state.syncFrequency,
      );
      await _backgroundService.registerBackgroundFetch();
    } else {
      await _backgroundService.cancelAllTasks();
    }
  }

  Future<void> _onToggleCellularData(
    SettingsToggleCellularData event,
    Emitter<SettingsState> emit,
  ) async {
    await _settingsRepository.setCellularDataEnabled(event.enabled);
    emit(state.copyWith(cellularDataEnabled: event.enabled));
  }

  Future<void> _onLoadStorageInfo(
    SettingsLoadStorageInfo event,
    Emitter<SettingsState> emit,
  ) async {
    final storageUsed = await _syncRepository.getStorageUsed();
    emit(state.copyWith(storageUsed: storageUsed));
  }

  Future<void> _onClearCache(
    SettingsClearCache event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await _syncRepository.clearCache();
    final storageUsed = await _syncRepository.getStorageUsed();
    emit(state.copyWith(storageUsed: storageUsed, isLoading: false));
  }
}
