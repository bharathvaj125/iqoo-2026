import 'package:flutter/material.dart';
import 'package:smriti/widgets/fade_slide_route.dart';
import 'package:intl/intl.dart';
import 'package:smriti/core/models/session.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/modules/asha/data/asha_repository.dart';
import 'package:smriti/modules/asha/screens/baseline_capture_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final _repo = AshaRepository.instance;

  @override
  Widget build(BuildContext context) {
    final patient = _repo.patientById(widget.patientId);
    final responses = _repo.responsesForPatient(widget.patientId);
    final missedCount = _repo.missedSessionCountFor(widget.patientId);

    return Scaffold(
      appBar: AppBar(title: Text(patient.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (patient.trendFlag != null) _trendFlagCard(patient.trendFlag!),
          _baselineCard(patient),
          const SizedBox(height: 12),
          _factsCard(patient, missedCount, responses.length),
          const SizedBox(height: 20),
          Text('Recent rounds', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Assisted and independent rounds are kept apart — performance with an ASHA '
            'beside her is not comparable to playing alone at home.',
            style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 12),
          if (responses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No rounds logged yet.'),
            )
          else
            ...responses.take(20).map(_responseRow),
        ],
      ),
    );
  }

  Widget _trendFlagCard(String flag) => Card(
        color: AppTheme.danger.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.flag_rounded, color: AppTheme.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Flagged for review',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.danger),
                    ),
                    const SizedBox(height: 4),
                    Text(flag),
                    const SizedBox(height: 8),
                    Text(
                      'A trend to raise with her, not a diagnosis. Diagnosis stays with a clinician.',
                      style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _baselineCard(patient) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Her baseline', style: Theme.of(context).textTheme.titleMedium)),
                if (patient.hasBaseline)
                  TextButton(onPressed: () => _captureBaseline(patient), child: const Text('Re-capture')),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Captured at onboarding. Later readings are compared against these, never against '
              'other patients or a population average.',
              style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 14),
            if (!patient.hasBaseline) ...[
              const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 20, color: AppTheme.accent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No baseline captured — her sessions are logged, but no trend can be calculated yet.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                  onPressed: () => _captureBaseline(patient),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Capture baseline'),
                ),
              ),
            ] else
              Row(
                children: [
                  _baselineStat('Reaction', '${patient.baselineReactionTimeMs} ms'),
                  _baselineStat('Errors', '${patient.baselineErrorRate}%'),
                  _baselineStat('Hints', '${patient.baselineHintDependence}%'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _baselineStat(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.6))),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _factsCard(patient, int missedCount, int roundCount) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _baselineStat('Language', patient.language),
              _baselineStat('Rounds logged', '$roundCount'),
              _baselineStat('Missed sessions', '$missedCount'),
            ],
          ),
        ),
      );

  Widget _responseRow(ResponseRecord r) {
    final (icon, color, label) = switch (r.marking) {
      ResponseMarking.independent => (Icons.check_circle_rounded, AppTheme.primary, 'Independent'),
      ResponseMarking.hint => (Icons.help_rounded, AppTheme.accent, 'Needed a hint'),
      ResponseMarking.noResponse => (Icons.remove_circle_rounded, AppTheme.danger, 'No response'),
    };

    final session = _repo.sessionById(r.sessionId);
    final assisted = session?.conductedBy != ConductedBy.independent;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        'Round ${r.roundNumber} · ${assisted ? 'ASHA-assisted' : 'Independent play'} · '
        '${DateFormat.MMMd().add_jm().format(r.timestamp)}',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Future<void> _captureBaseline(patient) async {
    final captured = await Navigator.of(context).push<bool>(
      fadeSlideRoute(
        builder: (_) => BaselineCaptureScreen(patientId: patient.id, patientName: patient.name),
      ),
    );
    if (captured == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Baseline saved')));
    }
  }
}
