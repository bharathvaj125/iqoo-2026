import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:smriti/core/models/reminder.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/modules/caregiver/data/caregiver_repository.dart';
import 'package:smriti/modules/caregiver/widgets/adherence_meter.dart';

class ReminderCard extends StatefulWidget {
  final Reminder reminder;
  final VoidCallback onChanged;

  const ReminderCard({super.key, required this.reminder, required this.onChanged});

  @override
  State<ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<ReminderCard> {
  final _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  IconData get _icon => switch (widget.reminder.type) {
        ReminderType.medicine => Icons.medication_rounded,
        ReminderType.hydration => Icons.water_drop_rounded,
        ReminderType.activity => Icons.self_improvement_rounded,
        ReminderType.appointment => Icons.event_rounded,
      };

  // Seeded demo reminders point at a placeholder URL with no real audio behind
  // it — only clips actually recorded through NewReminderScreen are playable.
  bool get _hasPlayableClip => widget.reminder.voiceClipUrl?.startsWith('seed://') == false;

  Future<void> _togglePlayback() async {
    if (!_hasPlayableClip) return;
    if (_isPlaying) {
      await _player.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }
    setState(() => _isPlaying = true);
    try {
      await _player.play(UrlSource(widget.reminder.voiceClipUrl!));
      _player.onPlayerComplete.first.then((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    } catch (_) {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  Future<void> _recordAck(AckStatus status) async {
    await CaregiverRepository.instance.recordAck(widget.reminder.id, status);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final adherence = CaregiverRepository.instance.adherenceFor(widget.reminder.id);
    final reminder = widget.reminder;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  child: Icon(_icon, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reminder.textLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text(reminder.schedule, style: TextStyle(color: Colors.black.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                if (reminder.voiceClipUrl != null)
                  IconButton(
                    tooltip: !_hasPlayableClip
                        ? 'Seed demo data — no real audio behind this one'
                        : (_isPlaying ? 'Stop' : 'Play voice clip'),
                    onPressed: _hasPlayableClip ? _togglePlayback : null,
                    icon: Icon(
                      _isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                      color: AppTheme.accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!adherence.hasData)
              Text(
                'No responses logged yet.',
                style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.55)),
              )
            else ...[
              AdherenceMeter(rate: adherence.rate),
              const SizedBox(height: 6),
              Text(
                '${adherence.acknowledged} acknowledged · ${adherence.missed} missed',
                style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55)),
              ),
              if (adherence.rate < 0.6) ...[
                const SizedBox(height: 8),
                const Text(
                  'Adherence is falling for this reminder — worth a check-in call.',
                  style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ],
            const SizedBox(height: 12),
            Tooltip(
              message: "Stands in for the ack arriving from the elder's device via sync",
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _recordAck(AckStatus.acknowledged),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Mark taken'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _recordAck(AckStatus.missed),
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Mark missed'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
