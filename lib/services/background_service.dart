import 'dart:developer' as developer;
import 'package:workmanager/workmanager.dart';

const String backgroundSyncTask = 'backgroundSyncTask';
const String backgroundFetchTask = 'backgroundFetchTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case backgroundSyncTask:
          // Full sync operation
          // Note: In production, this would call the sync service
          // For now, just log that background sync was triggered
          developer.log('Background sync task executed', name: 'BackgroundService');
          break;
        case backgroundFetchTask:
          // Quick check for changes
          developer.log('Background fetch task executed', name: 'BackgroundService');
          break;
      }
      return Future.value(true);
    } catch (e) {
      developer.log('Background task error: $e', name: 'BackgroundService');
      return Future.value(false);
    }
  });
}

class BackgroundService {
  Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  Future<void> registerBackgroundSync({
    Duration frequency = const Duration(hours: 1),
  }) async {
    await Workmanager().registerPeriodicTask(
      backgroundSyncTask,
      backgroundSyncTask,
      frequency: frequency,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  Future<void> registerBackgroundFetch({
    Duration frequency = const Duration(minutes: 15),
  }) async {
    await Workmanager().registerPeriodicTask(
      backgroundFetchTask,
      backgroundFetchTask,
      frequency: frequency,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }

  Future<void> cancelTask(String taskName) async {
    await Workmanager().cancelByUniqueName(taskName);
  }
}
