import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';
import '../services/sync_service.dart';
import '../services/local_file_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildAccountSection(context),
          const Divider(),
          _buildSyncSettings(context),
          const Divider(),
          _buildStorageSettings(context),
          const Divider(),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'ACCOUNT',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            ListTile(
              leading: state.userPhotoUrl != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(state.userPhotoUrl!),
                    )
                  : const CircleAvatar(child: Icon(Icons.person)),
              title: Text(state.userName ?? 'User'),
              subtitle: Text(state.userEmail ?? ''),
              trailing: TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthSignOut());
                },
                child: const Text('Sign Out'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSyncSettings(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'SYNC SETTINGS',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Sync Frequency'),
              subtitle: Text(_formatDuration(state.syncFrequency)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showSyncFrequencyDialog(context, state),
            ),
            ListTile(
              leading: const Icon(Icons.merge_type),
              title: const Text('Conflict Resolution'),
              subtitle: Text(
                _formatConflictResolution(state.conflictResolution),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showConflictResolutionDialog(context, state),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.cloud_sync),
              title: const Text('Background Sync'),
              subtitle: const Text('Sync automatically in background'),
              value: state.backgroundSyncEnabled,
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                  SettingsToggleBackgroundSync(value),
                );
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.signal_cellular_alt),
              title: const Text('Use Cellular Data'),
              subtitle: const Text('Sync over mobile data'),
              value: state.cellularDataEnabled,
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                  SettingsToggleCellularData(value),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStorageSettings(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final localService = LocalFileService();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'STORAGE',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('Storage Used'),
              subtitle: Text(localService.formatBytes(state.storageUsed)),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<SettingsBloc>().add(
                    const SettingsLoadStorageInfo(),
                  );
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Clear Cache'),
              subtitle: const Text('Delete all local files'),
              onTap: () => _showClearCacheDialog(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('ABOUT', style: Theme.of(context).textTheme.labelSmall),
        ),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Version'),
          subtitle: Text('0.1.0'),
        ),
        const ListTile(
          leading: Icon(Icons.description_outlined),
          title: Text('License'),
          subtitle: Text('Open Source'),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours < 1) {
      return '${duration.inMinutes} minutes';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hours';
    } else {
      return '${duration.inDays} days';
    }
  }

  String _formatConflictResolution(ConflictResolution resolution) {
    switch (resolution) {
      case ConflictResolution.driveWins:
        return 'Drive wins';
      case ConflictResolution.localWins:
        return 'Local wins';
      case ConflictResolution.newerWins:
        return 'Newer file wins';
    }
  }

  void _showSyncFrequencyDialog(BuildContext context, SettingsState state) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sync Frequency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFrequencyOption(
                context,
                'Every 15 minutes',
                const Duration(minutes: 15),
              ),
              _buildFrequencyOption(
                context,
                'Every hour',
                const Duration(hours: 1),
              ),
              _buildFrequencyOption(
                context,
                'Every 6 hours',
                const Duration(hours: 6),
              ),
              _buildFrequencyOption(
                context,
                'Daily',
                const Duration(hours: 24),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFrequencyOption(
    BuildContext context,
    String label,
    Duration duration,
  ) {
    return ListTile(
      title: Text(label),
      onTap: () {
        context.read<SettingsBloc>().add(SettingsUpdateSyncFrequency(duration));
        Navigator.pop(context);
      },
    );
  }

  void _showConflictResolutionDialog(
    BuildContext context,
    SettingsState state,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Conflict Resolution'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildConflictOption(
                context,
                'Drive wins',
                ConflictResolution.driveWins,
              ),
              _buildConflictOption(
                context,
                'Local wins',
                ConflictResolution.localWins,
              ),
              _buildConflictOption(
                context,
                'Newer file wins',
                ConflictResolution.newerWins,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConflictOption(
    BuildContext context,
    String label,
    ConflictResolution resolution,
  ) {
    return ListTile(
      title: Text(label),
      onTap: () {
        context.read<SettingsBloc>().add(
          SettingsUpdateConflictResolution(resolution),
        );
        Navigator.pop(context);
      },
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear Cache'),
          content: const Text(
            'This will delete all locally synced files. You can re-sync them later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<SettingsBloc>().add(const SettingsClearCache());
                Navigator.pop(dialogContext);
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}
