import 'dart:math';

import 'package:flutter/material.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/modules/asha/data/asha_repository.dart';

/// Baseline capture (novelty claim #3 — every elder is her own control).
///
/// In the shipped app these three readings come out of the patient's first play session:
/// the game instruments reaction latency, error rate and hint dependence while she plays,
/// so no test is ever administered. That game module is the other teammate's work, so the
/// measurement is stubbed here behind the same interface — the ASHA-facing flow, the
/// readings, and where they get stored are all real, only the source of the numbers is
/// standing in. The screen says so rather than pretending otherwise.
class BaselineCaptureScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const BaselineCaptureScreen({super.key, required this.patientId, required this.patientName});

  @override
  State<BaselineCaptureScreen> createState() => _BaselineCaptureScreenState();
}

class _BaselineCaptureScreenState extends State<BaselineCaptureScreen> {
  bool _running = false;
  bool _done = false;
  int _reactionTimeMs = 0;
  int _errorRate = 0;
  int _hintDependence = 0;

  Future<void> _runBaselineSession() async {
    setState(() => _running = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    // Stand-in for the instrumented play session — plausible spread, not real measurement.
    final random = Random();
    setState(() {
      _running = false;
      _done = true;
      _reactionTimeMs = 1800 + random.nextInt(1400);
      _errorRate = 8 + random.nextInt(18);
      _hintDependence = 10 + random.nextInt(22);
    });
  }

  Future<void> _save() async {
    await AshaRepository.instance.captureBaseline(
      patientId: widget.patientId,
      reactionTimeMs: _reactionTimeMs,
      errorRate: _errorRate,
      hintDependence: _hintDependence,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture baseline')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppTheme.primary.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patientName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Her first play session sets her personal baseline. Everything measured later is '
                    'compared against these numbers — never against other patients, and never against '
                    'a population average.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_done) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hand her the tablet and let her play one round. Nothing is presented to her as a '
                      'test — the readings come out of ordinary play.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Measurement is stubbed until the patient game module lands.',
                      style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _running ? null : _runBaselineSession,
                        icon: _running
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.play_arrow_rounded),
                        label: Text(_running ? 'Session in progress…' : 'Run baseline session'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Baseline readings', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _reading('Reaction latency', '$_reactionTimeMs ms'),
                    _reading('Error rate', '$_errorRate%'),
                    _reading('Hint dependence', '$_hintDependence%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: _save,
              child: const Text('Save as her baseline'),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _runBaselineSession, child: const Text('Run again')),
          ],
        ],
      ),
    );
  }

  Widget _reading(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.black.withValues(alpha: 0.7))),
            Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
