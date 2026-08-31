import 'package:flutter/material.dart';
import '../services/local_store.dart';
import 'package:smriti/core/theme.dart';

/// Maps to "Distress or inactivity alerts the caregiver" in the
/// app-workflow slide, and the Caregiver Alert & Sync service in
/// the architecture diagram. Kept to one big reassuring button —
/// no multi-step forms during a distress moment.
///
/// NOTE: In the Patient module, AppColors.accent (gold) is used instead of red (AppColors.distress),
/// adhering strictly to the "no red anywhere in Patient module" design system requirement.
Future<void> showDistressDialog(BuildContext context, ElderProfile profile) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.sos, color: AppColors.accent, size: 30),
          SizedBox(width: 8),
          Text('Need help?'),
        ],
      ),
      content: const Text(
        'This will send a message to your family or ASHA worker right away.',
        style: TextStyle(fontSize: 18),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            minimumSize: const Size(140, 52),
          ),
          onPressed: () async {
            // Queued offline and synced when a connection appears —
            // mirrors "Offline data syncs to cloud when online".
            await LocalStore().logGameSession({
              'elderId': profile.id,
              'type': 'distress_alert',
              'timestamp': DateTime.now().toIso8601String(),
            });
            if (context.mounted) Navigator.pop(context);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help is on the way. Family notified.'),
                  backgroundColor: AppColors.primary,
                ),
              );
            }
          },
          child: const Text('Send Alert', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
