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
  String? selectedLocalFolderPath;
  String? selectedLocalFolderBookmark;
  String? selectedLocalFolderDisplayName;
  bool isLoading = false;
  List<DriveFile> driveFolders = [];
  final List<DriveFile> _pathStack = [];
  // Maintains last search query for UX (used in TextField initialValue)
  String? _searchQuery;
  bool _isSearching = false;
  List<DriveFile> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadDriveFolders();
  }

  Future<void> _loadDriveFolders() async {
    setState(() => isLoading = true);
    try {
      final syncRepo = context.read<SyncRepository>();
      // Root level: list top-level folders (no parent constraint)
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
                      subtitle: Text(
                        selectedLocalFolderDisplayName ?? 'Choose a folder',
                      ),
                      onTap: _pickLocalFolder,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed:
                        selectedDriveFolder != null &&
                            selectedLocalFolderPath != null
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
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> openChild(DriveFile folder) async {
              setModalState(() => _isSearching = false);
              _pathStack.add(folder);
              setModalState(() {});
              final syncRepo = this.context.read<SyncRepository>();
              final children = await syncRepo.listDriveSubFolders(folder.id);
              setModalState(() {
                _searchResults = [];
                driveFolders = children;
              });
            }

            Future<void> goBack() async {
              if (_pathStack.isEmpty) return;
              _pathStack.removeLast();
              final syncRepo = this.context.read<SyncRepository>();
              if (_pathStack.isEmpty) {
                final roots = await syncRepo.searchDriveFolders();
                setModalState(() => driveFolders = roots);
              } else {
                final parent = _pathStack.last;
                final children = await syncRepo.listDriveSubFolders(parent.id);
                setModalState(() => driveFolders = children);
              }
            }

            Future<void> runSearch(String q) async {
              setModalState(() {
                _searchQuery = q.isEmpty ? null : q;
                _isSearching = q.trim().isNotEmpty;
              });
              if (_isSearching) {
                final results = await this.context
                    .read<SyncRepository>()
                    .searchDriveFoldersByName(q.trim());
                setModalState(() => _searchResults = results);
              } else {
                setModalState(() => _searchResults = []);
              }
            }

            final items = _isSearching ? _searchResults : driveFolders;

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  children: [
                    // Path breadcrumbs and back button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: _pathStack.isEmpty ? null : goBack,
                          ),
                          Expanded(
                            child: Text(
                              _pathStack.isEmpty
                                  ? 'My Drive'
                                  : _pathStack.map((f) => f.name).join(' / '),
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final folder = items[index];
                          return ListTile(
                            leading: const Icon(Icons.folder),
                            title: Text(folder.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => openChild(folder),
                            ),
                            onTap: () {
                              setState(() {
                                selectedDriveFolder = folder;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    // Search field at the bottom
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: TextField(
                        controller: TextEditingController(text: _searchQuery)
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: _searchQuery?.length ?? 0),
                          ),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search folders',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: runSearch,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _createSyncConfig() {
    if (selectedDriveFolder == null || selectedLocalFolderPath == null) return;

    final config = SyncConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      driveFolderId: selectedDriveFolder!.id,
      driveFolderName: selectedDriveFolder!.name,
      localFolderPath: selectedLocalFolderPath!,
      localFolderBookmark: selectedLocalFolderBookmark,
      localFolderDisplayName: selectedLocalFolderDisplayName,
      createdAt: DateTime.now(),
    );

    context.read<SyncBloc>().add(SyncAddConfig(config));
    Navigator.pop(context);
  }

  Future<void> _pickLocalFolder() async {
    try {
      final syncRepo = context.read<SyncRepository>();
      final dirInfo = await syncRepo.pickLocalDirectory();
      if (dirInfo == null) return;
      setState(() {
        selectedLocalFolderPath = dirInfo['path'];
        selectedLocalFolderBookmark = dirInfo['bookmark'];
        selectedLocalFolderDisplayName = dirInfo['displayName'];
      });
      final display = selectedLocalFolderDisplayName ?? 'Selected';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected local folder: $display')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting folder: $e')));
      }
    }
  }
}
