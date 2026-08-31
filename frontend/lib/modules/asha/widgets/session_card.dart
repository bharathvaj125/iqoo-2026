import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smriti/core/models/session.dart';
import 'package:smriti/core/theme.dart';

class SessionCard extends StatelessWidget {
  final CareSession session;
  final int patientCount;
  final VoidCallback onStart;
  final VoidCallback onMarkMissed;

  const SessionCard({
    super.key,
    required this.session,
    required this.patientCount,
    required this.onStart,
    required this.onMarkMissed,
  });

  String get _typeLabel => switch (session.type) {
        SessionType.group => 'Group session',
        SessionType.solo => 'Solo session',
        SessionType.outreach => 'Outreach visit',
      };

  IconData get _typeIcon => switch (session.type) {
        SessionType.group => Icons.groups_rounded,
        SessionType.solo => Icons.person_rounded,
        SessionType.outreach => Icons.directions_walk_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final isCompleted = session.status == SessionStatus.completed;
    final isMissed = session.status == SessionStatus.missed;
    final isInProgress = session.status == SessionStatus.inProgress;
    final isClosed = isCompleted || isMissed;

    final accent = isMissed ? AppTheme.danger : AppTheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: accent.withValues(alpha: isClosed ? 0.08 : 0.12),
              child: Icon(
                isCompleted
                    ? Icons.check_rounded
                    : isMissed
                        ? Icons.event_busy_rounded
                        : _typeIcon,
                color: isClosed ? accent.withValues(alpha: 0.7) : accent,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_typeLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat.jm().format(session.scheduledTime)} · $patientCount patient${patientCount == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 15, color: Colors.black.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            if (isCompleted)
              const _StatusChip(label: 'Completed', icon: Icons.check_circle_rounded, color: AppTheme.primary)
            else if (isMissed)
              const _StatusChip(label: 'Missed', icon: Icons.event_busy_rounded, color: AppTheme.danger)
            else ...[
              ElevatedButton(
                style: isInProgress
                    ? ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white)
                    : null,
                onPressed: onStart,
                child: Text(isInProgress ? 'Resume' : 'Start'),
              ),
              PopupMenuButton<String>(
                tooltip: 'More',
                onSelected: (_) => onMarkMissed(),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'missed',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.event_busy_rounded),
                      title: Text("Didn't attend"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: Icon(icon, size: 18, color: color),
      backgroundColor: Colors.transparent,
      side: BorderSide(color: color),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}
