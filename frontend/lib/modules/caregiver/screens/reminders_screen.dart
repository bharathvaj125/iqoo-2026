import 'package:flutter/material.dart';
import 'package:smriti/core/repository_listener.dart';
import 'package:smriti/modules/caregiver/data/caregiver_repository.dart';
import 'package:smriti/modules/caregiver/screens/new_reminder_screen.dart';
import 'package:smriti/modules/caregiver/widgets/reminder_card.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> with RepositoryListener {
  @override
  void initState() {
    super.initState();
    listenTo([CaregiverRepository.instance.onChange]);
  }

  @override
  Widget build(BuildContext context) {
    final reminders = CaregiverRepository.instance.reminders;

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      floatingActionButton: FloatingActionButton.extended(
        // This screen is both a tab in CaregiverHome and a pushed route from the
        // dashboard, so it can be mounted twice — keep its tag explicit.
        heroTag: 'fab-new-reminder',
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const NewReminderScreen()),
          );
          setState(() {});
          if (created == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder saved')));
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New reminder'),
      ),
      body: reminders.isEmpty
          ? const Center(child: Text('No reminders yet. Add one with the button below.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reminders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => ReminderCard(
                reminder: reminders[index],
                onChanged: () => setState(() {}),
              ),
            ),
    );
  }
}
