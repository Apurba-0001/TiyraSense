import 'package:flutter/material.dart';

enum SyncStatus {
  online,
  offline,
  pendingSync,
}

class SyncStatusBadge extends StatelessWidget {
  final SyncStatus status;
  final int pendingCount;

  const SyncStatusBadge({
    super.key,
    required this.status,
    this.pendingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (status) {
      case SyncStatus.online:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        icon = Icons.cloud_done_rounded;
        label = 'Online';
        break;
      case SyncStatus.offline:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        icon = Icons.cloud_off_rounded;
        label = 'Offline Mode';
        break;
      case SyncStatus.pendingSync:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        icon = Icons.sync_rounded;
        label = pendingCount > 0 ? '$pendingCount Pending Sync' : 'Sync Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
