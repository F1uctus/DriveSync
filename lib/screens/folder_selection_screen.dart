import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/sync/sync_bloc.dart';
import '../blocs/sync/sync_event.dart';
import '../models/sync_config.dart';
import '../services/google_drive_service.dart';
import '../repositories/sync_repository.dart';

class FolderSelectionScreen extends StatefulWidget {
  const FolderSelectionScreen({super.key});

  @override
  State<FolderSelectionScreen> createState() => _FolderSelectionScreenState();
}

class _FolderSelectionScreenState extends State<FolderSelectionScreen> {
  DriveFile? selectedDriveFolder;
  bool isLoading = false;
  List<DriveFile> driveFolders = [];

  @override
  void initState() {
    super.initState();
    _loadDriveFolders();
  }

  Future<void> _loadDriveFolders() async {
    setState(() => isLoading = true);
    try {
      final syncRepo = context.read<SyncRepository>();
      final folders = await syncRepo.searchDriveFolders();
      setState(() {
        driveFolders = folders;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading folders: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Folder Pair')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.cloud),
                      title: const Text('Google Drive Folder'),
                      subtitle: Text(
                        selectedDriveFolder?.name ?? 'Select a folder',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showDriveFolderPicker,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.phone_iphone),
                      title: const Text('Local Storage'),
                      subtitle: const Text('App documents folder'),
                      enabled: false,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: selectedDriveFolder != null
                        ? _createSyncConfig
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Create Sync Pair'),
                  ),
                ],
              ),
            ),
    );
  }

  void _showDriveFolderPicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: driveFolders.length,
          itemBuilder: (context, index) {
            final folder = driveFolders[index];
            return ListTile(
              leading: const Icon(Icons.folder),
              title: Text(folder.name),
              onTap: () {
                setState(() {
                  selectedDriveFolder = folder;
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _createSyncConfig() {
    if (selectedDriveFolder == null) return;

    final config = SyncConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      driveFolderId: selectedDriveFolder!.id,
      driveFolderName: selectedDriveFolder!.name,
      localFolderPath: 'local_${selectedDriveFolder!.id}',
      createdAt: DateTime.now(),
    );

    context.read<SyncBloc>().add(SyncAddConfig(config));
    Navigator.pop(context);
  }
}
