import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/patient_models.dart';
import '../services/companion.dart';
import '../services/companion_controller.dart';
import '../services/local_store.dart';
import '../services/reminder_service.dart';
import 'package:smriti/core/theme.dart';
import '../widgets/reminder_task_overlay.dart';

class _RecallQuestion {
  final String id;
  final String emoji;
  final String baseText; // naming form: "What is this?"
  final String functionalText; // easier, functional/descriptive form
  final String correct;
  final List<String> distractors;

  const _RecallQuestion({
    required this.id,
    required this.emoji,
    required this.baseText,
    required this.functionalText,
    required this.correct,
    required this.distractors,
  });
}

const _questions = [
  _RecallQuestion(
    id: 'teacup',
    emoji: '🫖',
    baseText: 'What is this?',
    functionalText: 'What do you use to drink your tea?',
    correct: 'Teacup',
    distractors: ['Umbrella', 'Drum', 'Boat'],
  ),
  _RecallQuestion(
    id: 'umbrella',
    emoji: '☂️',
    baseText: 'What is this?',
    functionalText: 'What do you use when it rains?',
    correct: 'Umbrella',
    distractors: ['Teacup', 'Cow', 'Moon'],
  ),
  _RecallQuestion(
    id: 'flute',
    emoji: '🪈',
    baseText: 'What is this?',
    functionalText: 'What do you use to play music?',
    correct: 'Flute',
    distractors: ['Boat', 'Water pot', 'Elephant'],
  ),
  _RecallQuestion(
    id: 'cow',
    emoji: '🐄',
    baseText: 'What is this?',
    functionalText: 'Which animal gives us milk?',
    correct: 'Cow',
    distractors: ['Elephant', 'Fish', 'Bird'],
  ),
  _RecallQuestion(
    id: 'boat',
    emoji: '🛶',
    baseText: 'What is this?',
    functionalText: 'What do you use to cross a river?',
    correct: 'Boat',
    distractors: ['Umbrella', 'Drum', 'Flute'],
  ),
];

/// Recognition-style game demonstrating the spec's per-question rephrase
/// ladder (never "wrong") and the reminder interrupt/resume flow.
///
/// Module id used for snapshots/records: `picture_recall`.
class PictureRecallScreen extends StatefulWidget {
  final ElderProfile profile;
  const PictureRecallScreen({super.key, required this.profile});

  @override
  State<PictureRecallScreen> createState() => _PictureRecallScreenState();
}

class _PictureRecallScreenState extends State<PictureRecallScreen> {
  static const _module = 'picture_recall';

  int _questionIndex = 0;
  int _hintLevel = 0; // 0 = base text, 1 = functional text, 2 = reduced options
  List<String> _shownOptions = [];
  bool _busy = false;
  bool _highlightCorrect = false;
  Timer? _highlightTimer;
  bool _interrupted = false;

  @override
  void initState() {
    super.initState();
    ReminderService.instance.addListener(_onReminderChange);
    _restoreOrStart();
  }

  Future<void> _restoreOrStart() async {
    final snap = await LocalStore().getGameSnapshot(_module);
    if (snap != null) {
      final state = snap.inProgressState;
      setState(() {
        _questionIndex = state['questionIndex'] ?? 0;
        _hintLevel = state['hintLevel'] ?? 0;
        _shownOptions = List<String>.from(state['shownOptions'] ?? _optionsFor(_questionIndex, 0));
      });
      await LocalStore().clearGameSnapshot(_module);
      await Companion.instance.say('resume_game');
      await Future.delayed(const Duration(milliseconds: 300));
      await _speakQuestion();
    } else {
      // Must go through setState: this runs after the first build (inside an
      // async initState continuation), so assigning the field directly never
      // schedules a rebuild and the grid is stuck showing its initial empty list.
      setState(() => _shownOptions = _optionsFor(0, 0));
      WidgetsBinding.instance.addPostFrameCallback((_) => _speakQuestion());
    }

    // If a reminder is already active (fired while this screen was
    // being built), show the overlay immediately.
    if (ReminderService.instance.activeReminder != null) {
      _snapshotAndInterrupt();
    }
  }

  List<String> _optionsFor(int qIndex, int hintLevel) {
    final q = _questions[qIndex];
    if (hintLevel < 2) {
      final opts = [q.correct, ...q.distractors]..shuffle(Random());
      return opts;
    }
    // hintLevel >= 2: drop distractors down to just one, per the spec's
    // "reduce from 4 choices to 2-3" step.
    final oneDistractor = (List<String>.from(q.distractors)..shuffle(Random())).first;
    final opts = [q.correct, oneDistractor]..shuffle(Random());
    return opts;
  }

  Future<void> _speakQuestion() async {
    final q = _questions[_questionIndex];
    final text = _hintLevel == 0 ? q.baseText : q.functionalText;
    await Companion.instance.sayCustom(text, CompanionExpression.thinking);
  }

  void _onReminderChange() {
    if (ReminderService.instance.activeReminder != null && !_interrupted) {
      _snapshotAndInterrupt();
    } else if (ReminderService.instance.activeReminder == null && _interrupted) {
      // Acknowledged elsewhere — handled by overlay's onAcknowledged too,
      // this covers the edge case of the listener firing first.
    }
  }

  Future<void> _snapshotAndInterrupt() async {
    _highlightTimer?.cancel();
    await LocalStore().saveGameSnapshot(
      GameSessionSnapshot(
        patientId: widget.profile.id,
        gameModule: _module,
        roundNumber: _questionIndex,
        inProgressState: {
          'questionIndex': _questionIndex,
          'hintLevel': _hintLevel,
          'shownOptions': _shownOptions,
        },
        pausedAt: DateTime.now(),
      ),
    );
    setState(() => _interrupted = true);
  }

  void _onReminderAcknowledged() {
    setState(() => _interrupted = false);
    // Snapshot already cleared on restore path; here we simply continue —
    // state was never destroyed since the overlay sits on top of the
    // same widget tree, but we explicitly reloaded from the persisted
    // snapshot in _restoreOrStart for the "app was killed" case, so this
    // covers the common in-memory case cleanly too.
  }

  Future<void> _logAndAdvance(ResponseMark mark, int hintLevelUsed) async {
    await LocalStore().logResponseRecord(
      ResponseRecord(
        patientId: widget.profile.id,
        gameModule: _module,
        questionId: _questions[_questionIndex].id,
        mark: mark,
        hintLevel: hintLevelUsed,
        timestamp: DateTime.now(),
      ),
    );

    if (_questionIndex >= _questions.length - 1) {
      await _completeRound();
      return;
    }

    setState(() {
      _questionIndex += 1;
      _hintLevel = 0;
      _shownOptions = _optionsFor(_questionIndex, 0);
      _highlightCorrect = false;
    });
    await _speakQuestion();
  }

  Future<void> _onOptionTap(String option) async {
    if (_busy || _interrupted) return;
    final q = _questions[_questionIndex];

    if (option == q.correct) {
      setState(() => _busy = true);
      await Companion.instance.say('correct');
      final mark = _hintLevel == 0 ? ResponseMark.independent : ResponseMark.hint;
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _busy = false);
      await _logAndAdvance(mark, _hintLevel);
      return;
    }

    // Wrong tap — escalate the rephrase ladder. Never say "wrong".
    setState(() => _busy = true);
    if (_hintLevel == 0) {
      await Companion.instance.say('rephrase_soft');
      setState(() {
        _hintLevel = 1;
        _shownOptions = _optionsFor(_questionIndex, 1);
      });
      await _speakQuestion();
    } else if (_hintLevel == 1) {
      await Companion.instance.say('rephrase_retry');
      setState(() {
        _hintLevel = 2;
        _shownOptions = _optionsFor(_questionIndex, 2);
      });
      await _speakQuestion();
    } else {
      // Final step: highlight the correct answer, then pass the round —
      // never repeat a flat wrong cycle.
      await Companion.instance.say('rephrase_highlight');
      setState(() => _highlightCorrect = true);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      setState(() {
        _highlightCorrect = false;
        _busy = false;
      });
      await _logAndAdvance(ResponseMark.hint, 3);
      return;
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _completeRound() async {
    final streak = await LocalStore().recordSessionCompleted(widget.profile.id);
    final isNewGame = await LocalStore().recordGameTried(_module);

    final newBadges = <RewardBadge>[];
    if (await LocalStore().awardBadgeIfNew(widget.profile.id, BadgeType.finishedToday)) {
      newBadges.add(RewardBadge(badgeType: BadgeType.finishedToday, earnedAt: DateTime.now()));
    }
    if (isNewGame &&
        await LocalStore().awardBadgeIfNew(widget.profile.id, BadgeType.triedNewGame)) {
      newBadges.add(RewardBadge(badgeType: BadgeType.triedNewGame, earnedAt: DateTime.now()));
    }
    if (streak.currentStreakDays == 5 &&
        await LocalStore().awardBadgeIfNew(widget.profile.id, BadgeType.streak5Day)) {
      newBadges.add(RewardBadge(badgeType: BadgeType.streak5Day, earnedAt: DateTime.now()));
    }
    if (streak.currentStreakDays == 10 &&
        await LocalStore().awardBadgeIfNew(widget.profile.id, BadgeType.streak10Day)) {
      newBadges.add(RewardBadge(badgeType: BadgeType.streak10Day, earnedAt: DateTime.now()));
    }

    if (!mounted) return;
    await Companion.instance.say('game_completed');
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await Companion.instance.say('session_end');

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Lovely playing with you! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔥 Streak: ${streak.currentStreakDays} day'
                '${streak.currentStreakDays == 1 ? '' : 's'}'),
            if (newBadges.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('New badges:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                children: newBadges
                    .map((b) => Chip(label: Text('${b.emoji} ${b.label}')))
                    .toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // dialog
              Navigator.pop(context); // this screen
            },
            child: const Text('Home'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _questionIndex = 0;
                _hintLevel = 0;
                _shownOptions = _optionsFor(0, 0);
              });
              _speakQuestion();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _repeatQuestion() async {
    if (_interrupted) return;
    await _speakQuestion();
  }

  @override
  void dispose() {
    ReminderService.instance.removeListener(_onReminderChange);
    _highlightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_questionIndex];
    final text = _hintLevel == 0 ? q.baseText : q.functionalText;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Picture Recall'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(q.emoji, style: const TextStyle(fontSize: 96)),
                  const SizedBox(height: 20),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _repeatQuestion,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Say it again', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.2,
                      children: _shownOptions.map((opt) {
                        final isCorrect = opt == q.correct;
                        final highlight = _highlightCorrect && isCorrect;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: highlight ? AppColors.accent.withOpacity(0.25) : Colors.white,
                            border: Border.all(
                              color: highlight ? AppColors.accent : AppColors.primary.withOpacity(0.25),
                              width: highlight ? 3 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: highlight
                                    ? AppColors.accent.withOpacity(0.4)
                                    : AppColors.cardShadow,
                                blurRadius: highlight ? 12 : 4,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => _onOptionTap(opt),
                              child: Center(
                                child: Text(
                                  opt,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_interrupted && ReminderService.instance.activeReminder != null)
            Positioned.fill(
              child: ReminderTaskOverlay(
                reminder: ReminderService.instance.activeReminder!,
                patientId: widget.profile.id,
                onAcknowledged: _onReminderAcknowledged,
              ),
            ),
        ],
      ),
    );
  }
}
