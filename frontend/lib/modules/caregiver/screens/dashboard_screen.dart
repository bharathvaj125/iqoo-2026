import 'package:flutter/material.dart';
import 'package:smriti/core/local_db/alert_store.dart';
import 'package:smriti/core/models/caregiver.dart';
import 'package:smriti/core/models/reminder.dart';
import 'package:smriti/core/repository_listener.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/modules/asha/data/asha_repository.dart';
import 'package:smriti/modules/caregiver/data/caregiver_repository.dart';
import 'package:smriti/modules/caregiver/screens/alerts_screen.dart';
import 'package:smriti/modules/caregiver/screens/reminders_screen.dart';
import 'package:smriti/widgets/sign_out_button.dart';

/// Decision-support, not just charts — every metric here has an action attached.
/// Built for someone checking in occasionally from another city or country.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RepositoryListener {
  final _repo = CaregiverRepository.instance;

  @override
  void initState() {
    super.initState();
    // Attendance comes from the ASHA module and flags from the shared alert store, so
    // this screen has three sources that can move underneath it.
    listenTo([_repo.onChange, AshaRepository.instance.onChange, AlertStore.instance.onChange]);
  }

  Future<void> _openAndRefresh(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  Future<void> _confirmFlagToAsha() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag to ASHA'),
        content: const Text(
          'This lets her ASHA worker know a scheduled session was missed, so she can follow up on the next '
          'visit or outreach round.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Flag it')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flagged to ASHA')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final digest = _repo.weeklyDigest;
    final profile = _repo.profile;
    final openAlerts = _repo.alerts.where((a) => !a.reviewed).length;
    final byType = _repo.adherenceByType().where((t) => t.hasData).toList();
    final patientName = _patientName(profile.patientId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          PopupMenuButton<CaregiverKind>(
            tooltip: 'Caregiver role',
            icon: const Icon(Icons.switch_account_rounded),
            initialValue: profile.kind,
            onSelected: (kind) async {
              await _repo.setCaregiverKind(kind);
              if (mounted) setState(() {});
            },
            itemBuilder: (context) => CaregiverKind.values
                .map((k) => PopupMenuItem(value: k, child: Text(k.label)))
                .toList(),
          ),
          const SignOutButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _contextBanner(profile, patientName),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Sessions this week',
                  value: digest.sessionsScheduled == 0 ? '—' : '${digest.sessionsAttended}/${digest.sessionsScheduled}',
                  color: digest.sessionsMissed > 0 ? AppTheme.accent : AppTheme.primary,
                  caption: digest.sessionsScheduled == 0 ? 'None scheduled' : null,
                  actionLabel: digest.sessionsMissed > 0 ? 'Flag to ASHA' : null,
                  onTap: digest.sessionsMissed > 0 ? _confirmFlagToAsha : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Reminder adherence',
                  value: digest.hasAdherenceData ? '${(digest.overallAdherenceRate * 100).round()}%' : '—',
                  color: digest.hasAdherenceData && digest.overallAdherenceRate < 0.7
                      ? AppTheme.danger
                      : AppTheme.primary,
                  caption: digest.hasAdherenceData ? null : 'No responses yet',
                  actionLabel: digest.hasAdherenceData && digest.overallAdherenceRate < 0.7 ? 'Review' : null,
                  onTap: digest.hasAdherenceData && digest.overallAdherenceRate < 0.7
                      ? () => _openAndRefresh(const RemindersScreen())
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatTile(
            label: 'Open trend flags',
            value: '$openAlerts',
            color: openAlerts > 0 ? AppTheme.danger : AppTheme.primary,
            caption: openAlerts == 0 ? 'Nothing needs review' : null,
            actionLabel: openAlerts > 0 ? 'Open Alerts' : null,
            onTap: openAlerts > 0 ? () => _openAndRefresh(const AlertsScreen()) : null,
          ),
          if (byType.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Adherence by type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Worst first — one category slipping matters more than the overall average.',
              style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 12),
            ...byType.map(_typeRow),
          ],
          const SizedBox(height: 24),
          Text('This week', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...digest.highlights.map(
            (h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(top: 7), child: Icon(Icons.circle, size: 6)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(h)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _patientName(String patientId) {
    try {
      return AshaRepository.instance.patientById(patientId).name;
    } catch (_) {
      return 'your family member';
    }
  }

  Widget _contextBanner(CaregiverProfile profile, String patientName) {
    final isFallback = profile.isAshaFallback;
    return Card(
      color: (isFallback ? AppTheme.accent : AppTheme.primary).withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              isFallback ? Icons.volunteer_activism_rounded : Icons.family_restroom_rounded,
              color: isFallback ? AppTheme.accent : AppTheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFallback ? 'Caring for $patientName as ASHA' : 'Caring for $patientName',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.kind.dashboardContext,
                    style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeRow(TypeAdherence t) {
    final percent = (t.rate * 100).round();
    final falling = t.rate < 0.7;
    final icon = switch (t.type) {
      ReminderType.medicine => Icons.medication_rounded,
      ReminderType.hydration => Icons.water_drop_rounded,
      ReminderType.activity => Icons.self_improvement_rounded,
      ReminderType.appointment => Icons.event_rounded,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: falling ? AppTheme.danger : AppTheme.primary),
          const SizedBox(width: 10),
          SizedBox(width: 96, child: Text(t.type.label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: t.rate,
                minHeight: 10,
                backgroundColor: Colors.black.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(falling ? AppTheme.danger : AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(
              '$percent% · ${t.total}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? actionLabel;
  final String? caption;
  final VoidCallback? onTap;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    this.actionLabel,
    this.caption,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.black.withValues(alpha: 0.6))),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
              if (caption != null) ...[
                const SizedBox(height: 4),
                Text(caption!, style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5))),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        actionLabel!,
                        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: color),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
