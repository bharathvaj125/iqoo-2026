import 'package:flutter/material.dart';
import 'package:smriti/core/local_db/alert_store.dart';
import 'package:smriti/core/repository_listener.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/modules/caregiver/data/caregiver_repository.dart';
import 'package:smriti/modules/caregiver/widgets/alert_tile.dart';

/// Trend flags only — never phrased as diagnosis. Diagnosis stays with a clinician.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with RepositoryListener {
  @override
  void initState() {
    super.initState();
    // Flags are raised by the ASHA module completing a session, not from this screen.
    listenTo([AlertStore.instance.onChange]);
  }

  @override
  Widget build(BuildContext context) {
    final repo = CaregiverRepository.instance;
    // Unreviewed first, most recent within each group first.
    final alerts = [...repo.alerts]
      ..sort((a, b) {
        if (a.reviewed != b.reviewed) return a.reviewed ? 1 : -1;
        return b.timestamp.compareTo(a.timestamp);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: alerts.isEmpty
          ? _emptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => AlertTile(
                alert: alerts[index],
                onReviewed: () async {
                  await repo.markAlertReviewed(alerts[index].id);
                  setState(() {});
                },
              ),
            ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_outlined, size: 48, color: AppTheme.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text(
                'Nothing flagged right now.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Flags appear here when her sessions start drifting from her own usual pattern.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      );
}
