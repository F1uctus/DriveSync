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
      child: ListTile(
        leading: Icon(
          Icons.folder_outlined,
          color: config.isEnabled ? Colors.blue : Colors.grey,
        ),
        title: Text(config.driveFolderName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.cloud, size: 14),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text('Google Drive', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.phone_iphone, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Local Storage',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (config.lastSyncedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last synced: ${_formatDateTime(config.lastSyncedAt!)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: Row(
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
        onTap: onTap,
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
