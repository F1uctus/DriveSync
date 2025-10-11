import 'package:flutter/material.dart';
import '../models/sync_state.dart';

class SyncStatusCard extends StatelessWidget {
  final SyncState syncState;

  const SyncStatusCard({super.key, required this.syncState});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusText(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (syncState.currentFileName != null)
                        Text(
                          syncState.currentFileName!,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (syncState.isInProgress) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: syncState.progress),
              const SizedBox(height: 8),
              Text(
                '${syncState.processedFiles} / ${syncState.totalFiles} files',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (syncState.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                syncState.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (syncState.lastSyncTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last sync: ${_formatDateTime(syncState.lastSyncTime!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (syncState.operation) {
      case SyncOperation.idle:
        return const Icon(Icons.cloud_done, color: Colors.green);
      case SyncOperation.checking:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncOperation.downloading:
        return const Icon(Icons.cloud_download, color: Colors.blue);
      case SyncOperation.uploading:
        return const Icon(Icons.cloud_upload, color: Colors.orange);
      case SyncOperation.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case SyncOperation.error:
        return const Icon(Icons.error, color: Colors.red);
    }
  }

  String _getStatusText() {
    switch (syncState.operation) {
      case SyncOperation.idle:
        return 'Ready to sync';
      case SyncOperation.checking:
        return 'Checking for changes...';
      case SyncOperation.downloading:
        return 'Downloading from Drive...';
      case SyncOperation.uploading:
        return 'Uploading to Drive...';
      case SyncOperation.completed:
        return 'Sync completed';
      case SyncOperation.error:
        return 'Sync error';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
