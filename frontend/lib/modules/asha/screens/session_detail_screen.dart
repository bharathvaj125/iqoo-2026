import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:smriti/widgets/fade_slide_route.dart';
import 'package:smriti/core/models/patient.dart';
import 'package:smriti/core/models/session.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/modules/asha/data/asha_repository.dart';
import 'package:smriti/modules/asha/screens/session_summary_screen.dart';
import 'package:smriti/widgets/companion_widget.dart';

/// In-session facilitation view: large tap targets, minimal steps per patient per round.
/// This is used live during a session on a shared tablet, not filled out afterward.
class SessionDetailScreen extends StatefulWidget {
  final String sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final _repo = AshaRepository.instance;
  int _round = 1;
  static const _gameModule = 'memory_matching';

  /// Writing a round is asynchronous. Without this guard a second tap — easy on a shared
  /// tablet being passed around — starts a second write while the first is still going,
  /// and the round counter and marks end up disagreeing with what was actually saved.
  bool _submitting = false;

  final Map<String, ResponseMarking?> _currentRoundMarks = {};

  // A self-contained TTS instance rather than importing the Patient module's
  // TtsService — ASHA and Patient are deliberately separate modules (see
  // ModuleCompanionHeader's doc comment), and this screen's use is simple
  // enough (announce the round, no mouth-sync) not to need that seam.
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  CompanionExpression _companionExpression = CompanionExpression.neutral;

  @override
  void initState() {
    super.initState();
    _announceRound();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _ensureTts() async {
    if (_ttsReady) return;
    await _tts.setLanguage('en-IN');
    // 0.5 reads as a normal, clear pace on most platforms — a slower elder-facing
    // rate belongs to the Patient module's own TtsService (see its doc comment);
    // this is the ASHA facilitator announcing a round, not addressing the elder.
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.05);
    await _tts.setVolume(1.0);
    _ttsReady = true;
  }

  /// Speaks the round prompt with a "speaking" expression, then settles into
  /// "listening" for the rest of the round — the companion visibly participates
  /// in conducting the session rather than sitting there as a static icon.
  Future<void> _announceRound() async {
    await _ensureTts();
    if (!mounted) return;
    setState(() => _companionExpression = CompanionExpression.encouraging);

    final completer = Completer<void>();
    _tts.setCompletionHandler(() {
      if (!completer.isCompleted) completer.complete();
    });
    _tts.setErrorHandler((_) {
      if (!completer.isCompleted) completer.complete();
    });

    try {
      final result = await _tts.speak('Round $_round. Watch closely, and mark how each patient responds.');
      if (result == 1) {
        await completer.future.timeout(const Duration(seconds: 10), onTimeout: () {});
      }
    } catch (_) {
      // No TTS engine on this platform (e.g. some web/desktop setups) — the
      // companion still settles into "listening" below, just without audio.
    }

    if (!mounted) return;
    setState(() => _companionExpression = CompanionExpression.listening);
  }

  @override
  Widget build(BuildContext context) {
    final session = _repo.sessionById(widget.sessionId);
    if (session == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Session not found')));
    }

    final patients = session.patientIds.map(_repo.patientById).toList();
    final allMarked = patients.every((p) => _currentRoundMarks[p.id] != null);

    return Scaffold(
      appBar: AppBar(
        title: Text('Round $_round · ${session.isGroup ? "Group" : "Solo"}'),
        actions: [
          TextButton.icon(
            // Ending is always available — an ASHA who opened a session by mistake, or
            // needs to stop early, was previously stuck here until she'd completed a
            // full round (this button stayed disabled at _round == 1). It only prompts
            // first when ending would throw away rounds that aren't saved yet.
            onPressed: !_submitting ? () => _endSession(session.id) : null,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('End session'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CompanionWidget(size: 96, expression: _companionExpression),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mark each patient for this round',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: patients.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final patient = patients[index];
                  final marking = _currentRoundMarks[patient.id];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patient.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _markButton('Independent', ResponseMarking.independent, marking, patient.id),
                              _markButton('Needed a hint', ResponseMarking.hint, marking, patient.id),
                              _markButton('No response', ResponseMarking.noResponse, marking, patient.id),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: allMarked && !_submitting ? () => _submitRound(session, patients) : null,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(allMarked ? 'Next round' : 'Mark every patient to continue'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRound(CareSession session, List<Patient> patients) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    for (final patient in patients) {
      await _repo.recordResponse(
        ResponseRecord(
          sessionId: session.id,
          patientId: patient.id,
          roundNumber: _round,
          marking: _currentRoundMarks[patient.id]!,
          gameModule: _gameModule,
          timestamp: DateTime.now(),
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _round += 1;
      _currentRoundMarks.clear();
      _submitting = false;
    });
    unawaited(_announceRound());
  }

  Future<void> _endSession(String sessionId) async {
    if (_submitting) return;

    // Nothing recorded, or the current round is only partway marked — ending now
    // would silently drop it, so confirm first. A round that's already been
    // submitted (round > 1, nothing pending) ends immediately, matching how the
    // button used to behave for that case.
    final hasUnsavedProgress = _round == 1 || _currentRoundMarks.isNotEmpty;
    if (hasUnsavedProgress) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('End session?'),
          content: Text(
            _round == 1 && _currentRoundMarks.isEmpty
                ? 'No rounds have been recorded yet for this session.'
                : "This round's marks haven't been saved yet and will be lost.",
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep going')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('End session')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _submitting = true);
    await _repo.completeSession(sessionId);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      fadeSlideRoute(builder: (_) => SessionSummaryScreen(sessionId: sessionId)),
    );
  }

  Widget _markButton(String label, ResponseMarking value, ResponseMarking? current, String patientId) {
    final selected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      // Marks are frozen while the round is being written, so what gets saved is what
      // was on screen when the ASHA committed it.
      onSelected: _submitting ? null : (_) => setState(() => _currentRoundMarks[patientId] = value),
      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.normal),
    );
  }
}
