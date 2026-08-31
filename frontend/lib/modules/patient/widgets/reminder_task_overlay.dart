import 'package:flutter/material.dart';

import '../models/patient_models.dart';
import '../services/companion.dart';
import '../services/reminder_service.dart';
import 'package:smriti/core/theme.dart';
import '../../../widgets/companion_widget.dart';

/// Shown on top of whatever the patient was doing when a reminder fires.
/// Per the spec: the game is paused underneath (the caller is responsible
/// for snapshotting state before showing this), the companion switches to
/// "task mode" and reads the reminder aloud, and a single big
/// acknowledgement tap resumes everything — never a form, never a typed
/// response.
class ReminderTaskOverlay extends StatefulWidget {
  final ReminderItem reminder;
  final String patientId;
  final VoidCallback onAcknowledged;

  const ReminderTaskOverlay({
    super.key,
    required this.reminder,
    required this.patientId,
    required this.onAcknowledged,
  });

  @override
  State<ReminderTaskOverlay> createState() => _ReminderTaskOverlayState();
}

class _ReminderTaskOverlayState extends State<ReminderTaskOverlay> {
  bool _acking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  Future<void> _speak() async {
    await Companion.instance.say('reminder_task_mode');
    // Read the reminder itself using the caregiver's recorded voice clip
    // where one exists (spec's "record once, reuse" feature); falls back
    // to TTS reading the reminder title, exactly like every other
    // companion line in this prototype.
    await Companion.instance.sayCustom(
      widget.reminder.title,
      CompanionExpression.gentle,
    );
  }

  Future<void> _onIDidIt() async {
    if (_acking) return;
    setState(() => _acking = true);
    await ReminderService.instance.acknowledge(widget.patientId);
    await Companion.instance.say('reminder_ack_thanks');
    if (mounted) widget.onAcknowledged();
  }

  IconData get _icon {
    switch (widget.reminder.category) {
      case 'medicine':
        return Icons.medication;
      case 'hydration':
        return Icons.local_drink;
      case 'appointment':
        return Icons.event;
      default:
        return Icons.notifications_active;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.97),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ListenableBuilder(
                listenable: Companion.instance.controller,
                builder: (context, _) {
                  return CompanionWidget(
                    expression: Companion.instance.controller.expression,
                    size: 160,
                  );
                },
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(_icon, color: AppColors.primary, size: 42),
              ),
              const SizedBox(height: 20),
              Text(
                widget.reminder.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _acking ? null : _onIDidIt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 72),
                    textStyle: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: _acking
                      ? const CircularProgressIndicator()
                      : const Text('✅  I did it!'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your game is waiting for you right where you left it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
