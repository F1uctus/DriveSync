import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/sync/sync_bloc.dart';
import 'blocs/sync/sync_event.dart';
import 'blocs/settings/settings_bloc.dart';
import 'blocs/settings/settings_event.dart';
import 'repositories/auth_repository.dart';
import 'repositories/sync_repository.dart';
import 'repositories/settings_repository.dart';
import 'services/google_drive_service.dart';
import 'services/local_file_service.dart';
import 'services/database_service.dart';
import 'services/background_service.dart';
import 'services/error_reporter.dart';
import 'screens/home_screen.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final driveService = GoogleDriveService();
  final localService = LocalFileService();
  final dbService = DatabaseService();
  final backgroundService = BackgroundService();

  await backgroundService.initialize();

  // Initialize repositories
  final authRepository = AuthRepository(driveService);
  final syncRepository = SyncRepository(
    driveService,
    localService,
    dbService,
    authRepository,
  );
  final settingsRepository = SettingsRepository();

  FlutterError.onError = (FlutterErrorDetails details) {
    Zone.current.handleUncaughtError(
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  runZonedGuarded(
    () {
      runApp(
        DriveSyncApp(
          authRepository: authRepository,
          syncRepository: syncRepository,
          settingsRepository: settingsRepository,
          backgroundService: backgroundService,
        ),
      );
    },
    (error, stack) async {
      await ErrorReporter.showError('Unexpected error', error, stack);
    },
  );
}

class DriveSyncApp extends StatelessWidget {
  final AuthRepository authRepository;
  final SyncRepository syncRepository;
  final SettingsRepository settingsRepository;
  final BackgroundService backgroundService;

  const DriveSyncApp({
    super.key,
    required this.authRepository,
    required this.syncRepository,
    required this.settingsRepository,
    required this.backgroundService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: syncRepository),
        RepositoryProvider.value(value: settingsRepository),
        RepositoryProvider.value(value: backgroundService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthBloc(authRepository)..add(const AuthInitialize()),
          ),
          BlocProvider(
            create: (context) =>
                SyncBloc(syncRepository)..add(const SyncLoadConfigs()),
          ),
          BlocProvider(
            create: (context) => SettingsBloc(
              settingsRepository,
              syncRepository,
              backgroundService,
            )..add(const SettingsLoad()),
          ),
        ],
        child: MaterialApp(
          navigatorKey: ErrorReporter.navigatorKey,
          title: 'Drive Sync',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
