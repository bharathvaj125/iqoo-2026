import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smriti/core/models/session.dart';
import 'package:smriti/core/repository_listener.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/modules/asha/data/asha_repository.dart';
import 'package:smriti/modules/asha/screens/new_session_screen.dart';
import 'package:smriti/modules/asha/screens/session_detail_screen.dart';
import 'package:smriti/modules/asha/widgets/session_card.dart';
import 'package:smriti/widgets/sign_out_button.dart';

/// Panel 1 of 3. Shows both group and solo/outreach sessions — group is the default,
/// core delivery mechanism; solo/outreach is the exception, not a separate primary flow.
class TodaySessionsScreen extends StatefulWidget {
  const TodaySessionsScreen({super.key});

  @override
  State<TodaySessionsScreen> createState() => _TodaySessionsScreenState();
}

class _TodaySessionsScreenState extends State<TodaySessionsScreen> with RepositoryListener {
  final _repo = AshaRepository.instance;

  @override
  void initState() {
    super.initState();
    listenTo([_repo.onChange]);
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _repo.sessionsToday;
    final upcoming = sessions.where((s) => s.status != SessionStatus.completed && s.status != SessionStatus.missed);
    final done = sessions.where((s) => s.status == SessionStatus.completed || s.status == SessionStatus.missed);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Sessions"),
        actions: const [SignOutButton()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat.yMMMMEEEEd().format(DateTime.now()),
                style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        // The panels live in an IndexedStack, so every FAB in this module is mounted at
        // once and they cannot share the default hero tag.
        heroTag: 'fab-new-session',
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const NewSessionScreen()),
          );
          setState(() {});
          if (created == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session scheduled')));
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New session'),
      ),
      body: sessions.isEmpty
          ? _emptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                ...upcoming.map(_card),
                if (done.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Done today',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.5),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...done.map(_card),
                ],
              ],
            ),
    );
  }

  Widget _card(CareSession session) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SessionCard(
          session: session,
          patientCount: session.patientIds.length,
          onStart: () async {
            if (session.status == SessionStatus.scheduled) {
              await _repo.startSession(session.id);
            }
            if (!mounted) return;
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SessionDetailScreen(sessionId: session.id)),
            );
            setState(() {});
          },
          onMarkMissed: () => _confirmMissed(session),
        ),
      );

  Future<void> _confirmMissed(CareSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mark as didn't attend"),
        content: Text(
          'This records the session as missed for all ${session.patientIds.length} '
          'patient${session.patientIds.length == 1 ? '' : 's'} on it, and shows on their caregiver dashboard.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Mark missed')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.markSessionMissed(session.id);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session marked missed')));
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_available_rounded, size: 48, color: AppTheme.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text(
                'No sessions scheduled for today.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Schedule a group session, or an outreach visit for someone who cannot travel.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      );
}
