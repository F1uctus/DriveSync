import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/sync/sync_bloc.dart';
import '../blocs/sync/sync_event.dart';
import '../blocs/sync/sync_state.dart';
import '../widgets/folder_pair_tile.dart';
import '../widgets/sync_status_card.dart';
import 'settings_screen.dart';
import 'folder_selection_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState.status == AuthStatus.unauthenticated) {
          return const AuthScreen();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Drive Sync'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: BlocBuilder<SyncBloc, SyncBlocState>(
            builder: (context, syncState) {
              if (syncState.status == SyncBlocStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<SyncBloc>().add(const SyncLoadConfigs());
                },
                child: CustomScrollView(
                  slivers: [
                    if (syncState.currentSyncState != null)
                      SliverToBoxAdapter(
                        child: SyncStatusCard(
                          syncState: syncState.currentSyncState!,
                        ),
                      ),
                    if (syncState.configs.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No sync folders configured',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to add a folder pair',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final config = syncState.configs[index];
                          return FolderPairTile(
                            config: config,
                            onTap: () {},
                            onDelete: () {
                              _showDeleteDialog(context, config.id);
                            },
                            onSync: () {
                              context.read<SyncBloc>().add(
                                SyncStartManual(config),
                              );
                            },
                          );
                        }, childCount: syncState.configs.length),
                      ),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FolderSelectionScreen(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String configId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Folder Pair'),
          content: const Text(
            'This will remove the sync configuration and delete local files. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<SyncBloc>().add(SyncDeleteConfig(configId));
                Navigator.pop(dialogContext);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
