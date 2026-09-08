import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smriti/core/local_db/alert_store.dart';
import 'package:smriti/core/models/reminder.dart';
import 'package:smriti/core/repository_listener.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/modules/asha/data/asha_repository.dart';
import 'package:smriti/modules/caregiver/data/caregiver_repository.dart';

/// Async weekly digest — a deliberate design choice for a caregiver checking in
/// occasionally from another city or country, not a live feed they're expected to watch.
class DigestScreen extends StatefulWidget {
  const DigestScreen({super.key});

  @override
  State<DigestScreen> createState() => _DigestScreenState();
}

class _DigestScreenState extends State<DigestScreen> with RepositoryListener {
  @override
  void initState() {
    super.initState();
    listenTo([
      CaregiverRepository.instance.onChange,
      AshaRepository.instance.onChange,
      AlertStore.instance.onChange,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final repo = CaregiverRepository.instance;
    final digest = repo.weeklyDigest;
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly digest')),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${DateFormat.MMMd().format(weekStart)} – ${DateFormat.MMMd().format(now)}',
              style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 12),
            Card(
              color: AppTheme.primary.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('At a glance', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _glance(
                          'Attended',
                          digest.sessionsScheduled == 0 ? '—' : '${digest.sessionsAttended}',
                          AppTheme.primary,
                        ),
                        _glance(
                          'Missed',
                          digest.sessionsScheduled == 0 ? '—' : '${digest.sessionsMissed}',
                          digest.sessionsMissed > 0 ? AppTheme.danger : AppTheme.primary,
                        ),
                        _glance(
                          'Adherence',
                          digest.hasAdherenceData ? '${(digest.overallAdherenceRate * 100).round()}%' : '—',
                          digest.hasAdherenceData && digest.overallAdherenceRate < 0.7
                              ? AppTheme.danger
                              : AppTheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Highlights', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...digest.highlights.map(
              (h) => Card(
                child: ListTile(
                  leading: const Icon(Icons.notes_rounded),
                  title: Text(h),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('By reminder type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...repo.adherenceByType().where((t) => t.hasData).map(
                  (t) => Card(
                    child: ListTile(
                      title: Text(t.type.label),
                      subtitle: Text('${t.acknowledged} acknowledged · ${t.missed} missed'),
                      trailing: Text(
                        '${(t.rate * 100).round()}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: t.rate < 0.7 ? AppTheme.danger : AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 24),
            Text(
              'Everything here is drawn from her sessions and reminder responses over the last seven '
              'days. Nothing on this page is an assessment or a diagnosis.',
              style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.55)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glance(String label, String value, Color color) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6))),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      );
}
