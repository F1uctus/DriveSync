import 'package:shared_preferences/shared_preferences.dart';
import '../services/sync_service.dart';

class SettingsRepository {
  static const String _syncFrequencyKey = 'sync_frequency';
  static const String _conflictResolutionKey = 'conflict_resolution';
  static const String _backgroundSyncKey = 'background_sync_enabled';
  static const String _cellularDataKey = 'cellular_data_enabled';

  Future<Duration> getSyncFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    final hours = prefs.getInt(_syncFrequencyKey) ?? 1;
    return Duration(hours: hours);
  }

  Future<void> setSyncFrequency(Duration frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_syncFrequencyKey, frequency.inHours);
  }

  Future<ConflictResolution> getConflictResolution() async {
    final prefs = await SharedPreferences.getInstance();
    final index =
        prefs.getInt(_conflictResolutionKey) ?? 2; // Default: newerWins
    return ConflictResolution.values[index];
  }

  Future<void> setConflictResolution(ConflictResolution resolution) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_conflictResolutionKey, resolution.index);
  }

  Future<bool> isBackgroundSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_backgroundSyncKey) ?? true;
  }

  Future<void> setBackgroundSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backgroundSyncKey, enabled);
  }

  Future<bool> isCellularDataEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cellularDataKey) ?? false;
  }

  Future<void> setCellularDataEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cellularDataKey, enabled);
  }
}
