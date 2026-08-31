import 'package:flutter/material.dart';

import '../models/patient_models.dart';
import '../services/companion.dart';
import '../services/companion_controller.dart';
import '../services/local_store.dart';
import 'package:smriti/core/theme.dart';

/// Time-of-day triggered safety/routine nudge (Phase 3 — Daily Living
/// Guidance). Distinct from caregiver reminders and from scored gameplay:
/// a single 10-15 second interaction, a big "Did you do it?" yes/no tap,
/// companion praise either way, no scoring, no failure state.
///
/// Shown as a dismissable banner on the home screen when one is due for
/// the current time-of-day bucket (see [LocalStore.getDueDailyLivingPrompt]).
class DailyLivingCard extends StatefulWidget {
  final String patientId;
  final DailyLivingPrompt prompt;
  final VoidCallback onDismissed;

  const DailyLivingCard({
    super.key,
    required this.patientId,
    required this.prompt,
    required this.onDismissed,
  });

  @override
  State<DailyLivingCard> createState() => _DailyLivingCardState();
}

class _DailyLivingCardState extends State<DailyLivingCard> {
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Companion.instance.sayCustom(widget.prompt.text, CompanionExpression.gentle);
    });
  }

  Future<void> _respond(bool didIt) async {
    await LocalStore().logDailyLivingCompletion(widget.patientId, widget.prompt.id, didIt);
    await LocalStore().markDailyLivingPromptShown(widget.prompt.triggerTimeOfDay);
    setState(() => _answered = true);
    await Companion.instance.say(didIt ? 'daily_living_praise' : 'daily_living_gentle');
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_twilight, color: AppColors.success, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.prompt.text,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!_answered)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond(false),
                    child: const Text('Not yet'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respond(true),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      backgroundColor: AppColors.success,
                    ),
                    child: const Text('Did you do it? ✓'),
                  ),
                ),
              ],
            )
          else
            const Text('Thank you! 🌟', style: TextStyle(fontSize: 16, color: AppColors.success)),
        ],
      ),
    );
  }
}
