import 'package:flutter/material.dart';
import '../models/sync_config.dart';

class FolderPairTile extends StatelessWidget {
  final SyncConfig config;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onSync;

  const FolderPairTile({
    super.key,
    required this.config,
    required this.onTap,
    required this.onDelete,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              color: config.isEnabled ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 12),
            // Name column
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.driveFolderName,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (config.lastSyncedAt != null)
                    Text(
                      'Last synced: ${_formatDateTime(config.lastSyncedAt!)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Drive column
            Expanded(
              flex: 2,
              child: Row(
                children: const [
                  Icon(Icons.cloud, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Google Drive',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Local column
            Expanded(
              flex: 2,
              child: Row(
                children: const [
                  Icon(Icons.phone_iphone, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Local Storage',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: config.isEnabled ? onSync : null,
                  tooltip: 'Sync now',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
