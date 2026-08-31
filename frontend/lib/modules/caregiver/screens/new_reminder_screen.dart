import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:smriti/core/models/reminder.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/modules/caregiver/data/caregiver_repository.dart';

/// Novelty claim #6: record once, reuse across reminders. Falls back to TTS if no
/// clip is recorded — this is also the fallback for languages with no TTS model at all.
class NewReminderScreen extends StatefulWidget {
  const NewReminderScreen({super.key});

  @override
  State<NewReminderScreen> createState() => _NewReminderScreenState();
}

class _NewReminderScreenState extends State<NewReminderScreen> {
  final _labelController = TextEditingController();
  final _scheduleController = TextEditingController();
  ReminderType _type = ReminderType.medicine;

  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _saving = false;
  String? _selectedClipUrl;

  @override
  void dispose() {
    _labelController.dispose();
    _scheduleController.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _selectedClipUrl = path;
      });
      return;
    }

    if (await _recorder.hasPermission()) {
      await _recorder.start(const RecordConfig(), path: 'reminder_voice_clip_${DateTime.now().millisecondsSinceEpoch}.m4a');
      setState(() => _isRecording = true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is needed to record a voice clip')),
      );
    }
  }

  Future<void> _togglePreview() async {
    if (_selectedClipUrl == null) return;
    if (_isPlaying) {
      await _player.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }
    setState(() => _isPlaying = true);
    try {
      await _player.play(UrlSource(_selectedClipUrl!));
      _player.onPlayerComplete.first.then((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    } catch (_) {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await CaregiverRepository.instance.addReminder(
      Reminder(
        id: 'r-${DateTime.now().millisecondsSinceEpoch}',
        patientId: 'p1',
        createdBy: 'caregiver-demo-1',
        type: _type,
        schedule: _scheduleController.text.trim(),
        textLabel: _labelController.text.trim(),
        voiceClipUrl: _selectedClipUrl,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final previousClips = CaregiverRepository.instance.voiceClips;

    return Scaffold(
      appBar: AppBar(title: const Text('New reminder')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ReminderType.values
                .map((t) => ChoiceChip(
                      label: Text(t.label),
                      selected: _type == t,
                      onSelected: (_) => setState(() => _type = t),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _labelController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'What (e.g. "Take blood pressure tablet")'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _scheduleController,
            decoration: const InputDecoration(labelText: 'When (e.g. "Daily 08:00, 20:00")'),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Voice clip (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    'Record ~15s in your voice. Plays offline on her device, in her language, forever. '
                    'Leave blank to use text-to-speech instead.',
                    style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRecording ? AppTheme.danger : AppTheme.accent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _toggleRecording,
                        icon: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded),
                        label: Text(_isRecording ? 'Stop recording' : 'Record voice clip'),
                      ),
                      if (_selectedClipUrl != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: _isPlaying ? 'Stop' : 'Preview',
                          onPressed: _togglePreview,
                          icon: Icon(_isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded),
                          color: AppTheme.primary,
                        ),
                        const Icon(Icons.check_circle_rounded, color: AppTheme.primary),
                      ],
                    ],
                  ),
                  if (previousClips.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Or reuse a clip you already recorded', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: previousClips.asMap().entries.map((entry) {
                        final selected = _selectedClipUrl == entry.value;
                        return ChoiceChip(
                          avatar: const Icon(Icons.record_voice_over_rounded, size: 16),
                          label: Text('Clip ${entry.key + 1}'),
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedClipUrl = selected ? null : entry.value),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            onPressed: _labelController.text.trim().isEmpty || _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save reminder'),
          ),
        ],
      ),
    );
  }
}
