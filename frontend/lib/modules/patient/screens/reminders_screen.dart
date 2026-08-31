import 'package:flutter/material.dart';

import '../services/local_store.dart';
import '../services/reminder_service.dart';
import 'package:smriti/core/theme.dart';
import '../widgets/companion_corner.dart';

/// Voice reminders: meds, water, appointments. Backed by the shared
/// [ReminderService] so a reminder firing here is the same event that
/// interrupts gameplay elsewhere in the app (see the spec's
/// interrupt/resume flow).
///
/// Each card includes a "Test: ring now" action — the actual scheduled
/// firing happens automatically at [ReminderItem.timeOfDay] via
/// [ReminderService]'s clock, but a demo trigger makes the interrupt
/// flow easy to show without waiting for wall-clock time.
class RemindersScreen extends StatefulWidget {
  final ElderProfile? profile;
  const RemindersScreen({super.key, this.profile});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  void initState() {
    super.initState();
    ReminderService.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    ReminderService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  IconData _iconFor(String category) {
    switch (category) {
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
    final reminders = ReminderService.instance.reminders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: reminders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final r = reminders[i];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        (r.acknowledgedToday ? AppColors.successAccent : AppColors.accent).withValues(alpha: 0.15),
                    child: Icon(_iconFor(r.category),
                        color: r.acknowledgedToday ? AppColors.successAccent : AppColors.accent, size: 30),
                  ),
                  title: Text(r.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  subtitle: Text(r.timeOfDay, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  trailing: r.acknowledgedToday
                      ? const Icon(Icons.check_circle, color: AppColors.successAccent, size: 28)
                      : TextButton(
                          onPressed: () => ReminderService.instance.fireForDemo(r.id),
                          child: const Text('Test: ring now'),
                        ),
                ),
              );
            },
          ),
          const Positioned(
            top: 6,
            right: 12,
            child: CompanionCorner(size: 52),
          ),
        ],
      ),
    );
  }
}
