import 'package:flutter/material.dart';
import 'package:smriti/core/models/session.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/modules/asha/data/asha_repository.dart';

/// Shown once a session is marked complete — a quick per-patient tally an
/// ASHA can glance at before moving to the next session, not a report she
/// has to compile herself.
class SessionSummaryScreen extends StatelessWidget {
  final String sessionId;

  const SessionSummaryScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final repo = AshaRepository.instance;
    final session = repo.sessionById(sessionId);
    final responses = repo.responsesForSession(sessionId);
    final roundCount = responses.map((r) => r.roundNumber).toSet().length;

    return Scaffold(
      appBar: AppBar(title: const Text('Session complete'), automaticallyImplyLeading: false),
      body: session == null
          ? const Center(child: Text('Session not found'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            '$roundCount round${roundCount == 1 ? '' : 's'} logged for '
                            '${session.patientIds.length} patient${session.patientIds.length == 1 ? '' : 's'}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...session.patientIds.map((patientId) {
                  final patient = repo.patientById(patientId);
                  final patientResponses = responses.where((r) => r.patientId == patientId);
                  final independent = patientResponses.where((r) => r.marking == ResponseMarking.independent).length;
                  final hint = patientResponses.where((r) => r.marking == ResponseMarking.hint).length;
                  final noResponse = patientResponses.where((r) => r.marking == ResponseMarking.noResponse).length;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patient.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 4,
                            children: [
                              _tally('Independent', independent, AppTheme.primary),
                              _tally('Hint', hint, AppTheme.accent),
                              _tally('No response', noResponse, AppTheme.danger),
                            ],
                          ),
                          if (patient.trendFlag != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.flag_rounded, size: 18, color: AppTheme.danger),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    patient.trendFlag!,
                                    style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Done'),
                ),
              ],
            ),
    );
  }

  Widget _tally(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: $count'),
      ],
    );
  }
}
