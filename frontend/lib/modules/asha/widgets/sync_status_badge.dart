import 'package:flutter/material.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/modules/asha/data/asha_repository.dart';

class SyncStatusBadge extends StatelessWidget {
  final SyncState state;

  const SyncStatusBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (state) {
      SyncState.queued => ('Queued', Colors.black54, Icons.schedule_rounded),
      SyncState.syncing => ('Syncing', AppTheme.accent, Icons.sync_rounded),
      SyncState.synced => ('Synced', AppTheme.primary, Icons.check_circle_rounded),
    };

    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide.none,
    );
  }
}
