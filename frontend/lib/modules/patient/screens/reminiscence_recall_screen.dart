import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/patient_models.dart';
import '../services/companion.dart';
import '../services/local_store.dart';
import '../services/reminder_service.dart';
import '../services/audio_cue_service.dart';
import 'package:smriti/core/theme.dart';
import '../widgets/reminder_task_overlay.dart';
import '../widgets/companion_corner.dart';
import '../../../widgets/companion_widget.dart';

/// Regional distractor bank keyed by state-level cultural pack (spec MVP:
/// "match content to the patient's registered state-level cultural pack").
/// Distractors are drawn from here, not random junk, so a wrong option
/// still feels locally plausible rather than absurd.
const Map<String, List<String>> _regionalDistractorPack = {
  'Assam': ['Marigold', 'Rice', 'Betel nut', 'Gamosa', 'Bihu song', 'Tea leaves'],
  'Meghalaya': ['Orange', 'Bamboo shoot', 'Betel leaf', 'Khasi shawl', 'Pineapple'],
  'Manipur': ['Lotus', 'Fish curry', 'Phanek cloth', 'Rice beer', 'Bamboo'],
  'Nagaland': ['Chilli', 'Bamboo shoot', 'Shawl', 'Rice beer', 'Hornbill feather'],
  'Tripura': ['Bamboo', 'Rice', 'Pineapple', 'Fish', 'Cotton cloth'],
};

List<String> _distractorsFor(String state) =>
    _regionalDistractorPack[state] ?? _regionalDistractorPack['Assam']!;

/// Personalization-loop game (Phase 2): pulls a stored [PersonalFact] and
/// turns it into a multiple-choice recall question, e.g.
/// "What did your daughter bring you last time?" -> Jasmine (correct) plus
/// three regional distractors. Same zero-failure rephrase ladder as
/// Picture Recall. Falls back to a warm "still getting to know you"
/// message if the Personal Fact Bank is empty rather than showing no
/// content or an error.
///
/// Module id used for snapshots/records: `reminiscence_recall`.
class ReminiscenceRecallScreen extends StatefulWidget {
  final ElderProfile profile;
  const ReminiscenceRecallScreen({super.key, required this.profile});

  @override
  State<ReminiscenceRecallScreen> createState() => _ReminiscenceRecallScreenState();
}

class _RecallRound {
  final PersonalFact fact;
  final String baseText;
  final String functionalText;
  final List<String> distractors;
  const _RecallRound({
    required this.fact,
    required this.baseText,
    required this.functionalText,
    required this.distractors,
  });
}

class _ReminiscenceRecallScreenState extends State<ReminiscenceRecallScreen> {
  static const _module = 'reminiscence_recall';

  List<_RecallRound> _rounds = [];
  bool _loading = true;
  int _roundIndex = 0;
  int _hintLevel = 0;
  List<String> _shownOptions = [];
  bool _busy = false;
  bool _highlightCorrect = false;
  bool _interrupted = false;

  @override
  void initState() {
    super.initState();
    ReminderService.instance.addListener(_onReminderChange);
    _load();
  }

  Future<void> _load() async {
    final facts = await LocalStore().getPersonalFacts(widget.profile.id);
    if (facts.isEmpty) {
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Companion.instance.say('reminiscence_no_facts_yet'),
      );
      return;
    }

    final distractorPool = _distractorsFor(widget.profile.state);
    final rounds = facts.map((f) {
      final pool = List<String>.from(distractorPool)..remove(f.value);
      pool.shuffle(Random());
      return _RecallRound(
        fact: f,
        baseText: _questionFor(f, easy: false),
        functionalText: _questionFor(f, easy: true),
        distractors: pool.take(3).toList(),
      );
    }).toList();
    rounds.shuffle(Random());

    final snap = await LocalStore().getGameSnapshot(_module);
    setState(() {
      _rounds = rounds;
      _loading = false;
    });

    if (snap != null) {
      final state = snap.inProgressState;
      setState(() {
        _roundIndex = (state['roundIndex'] ?? 0).clamp(0, _rounds.length - 1);
        _hintLevel = state['hintLevel'] ?? 0;
        _shownOptions =
            List<String>.from(state['shownOptions'] ?? _optionsFor(_roundIndex, 0));
      });
      await LocalStore().clearGameSnapshot(_module);
      await Companion.instance.say('resume_game');
      await Future.delayed(const Duration(milliseconds: 300));
      await _speakQuestion();
    } else {
      setState(() => _shownOptions = _optionsFor(0, 0));
      WidgetsBinding.instance.addPostFrameCallback((_) => _speakQuestion());
    }

    if (ReminderService.instance.activeReminder != null) {
      _snapshotAndInterrupt();
    }
  }

  String _questionFor(PersonalFact f, {required bool easy}) {
    final entity = f.entity;
    switch (f.category) {
      case 'gift_from_family':
        return easy
            ? 'Think about a gift someone gave you — what was it?'
            : 'What did your $entity bring you last time?';
      case 'hometown':
        return easy ? 'What is a special place from your life?' : 'What did you tell me about $entity?';
      case 'hobby':
        return easy ? 'What do you enjoy doing?' : 'What did you say you enjoy — $entity?';
      case 'pet':
        return easy ? "What is your pet's name?" : 'What did you name your $entity?';
      case 'festival':
        return easy ? 'What festival do you love?' : 'Which festival did you say you love?';
      case 'food':
        return easy ? 'What food do you like?' : 'What did you say your favourite food is?';
      case 'past_occupation':
        return easy ? 'What kind of work did you used to do?' : 'What was your $entity?';
      case 'family_visit':
        return easy ? 'Who visited you recently?' : 'Who came to see you about $entity?';
      default:
        return easy ? 'What did you tell me before?' : 'What did you say about $entity?';
    }
  }

  List<String> _optionsFor(int roundIndex, int hintLevel) {
    final r = _rounds[roundIndex];
    if (hintLevel < 2) {
      final opts = [r.fact.value, ...r.distractors]..shuffle(Random());
      return opts;
    }
    final oneDistractor = (List<String>.from(r.distractors)..shuffle(Random())).first;
    final opts = [r.fact.value, oneDistractor]..shuffle(Random());
    return opts;
  }

  Future<void> _speakQuestion() async {
    if (_rounds.isEmpty) return;
    final r = _rounds[_roundIndex];
    final text = _hintLevel == 0 ? r.baseText : r.functionalText;
    await Companion.instance.sayCustom(text, CompanionExpression.neutral);
  }

  void _onReminderChange() {
    if (ReminderService.instance.activeReminder != null && !_interrupted) {
      _snapshotAndInterrupt();
    }
  }

  Future<void> _snapshotAndInterrupt() async {
    await LocalStore().saveGameSnapshot(
      GameSessionSnapshot(
        patientId: widget.profile.id,
        gameModule: _module,
        roundNumber: _roundIndex,
        inProgressState: {
          'roundIndex': _roundIndex,
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
  }

  Future<void> _logAndAdvance(ResponseMark mark, int hintLevelUsed) async {
    final r = _rounds[_roundIndex];
    await LocalStore().logResponseRecord(
      ResponseRecord(
        patientId: widget.profile.id,
        gameModule: _module,
        questionId: r.fact.id,
        mark: mark,
        hintLevel: hintLevelUsed,
        fromPersonalFact: true,
        timestamp: DateTime.now(),
      ),
    );

    if (_roundIndex >= _rounds.length - 1) {
      await _completeRound();
      return;
    }

    setState(() {
      _roundIndex += 1;
      _hintLevel = 0;
      _shownOptions = _optionsFor(_roundIndex, 0);
      _highlightCorrect = false;
    });
    await _speakQuestion();
  }

  Future<void> _onOptionTap(String option) async {
    if (_busy || _interrupted) return;
    final r = _rounds[_roundIndex];

    if (option == r.fact.value) {
      setState(() => _busy = true);
      AudioCueService.instance.play('correct');
      await Companion.instance.say('correct');
      final mark = _hintLevel == 0 ? ResponseMark.independent : ResponseMark.hint;
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _busy = false);
      await _logAndAdvance(mark, _hintLevel);
      return;
    }

    setState(() => _busy = true);
    AudioCueService.instance.play('miss');
    if (_hintLevel == 0) {
      await Companion.instance.say('rephrase_soft');
      setState(() {
        _hintLevel = 1;
        _shownOptions = _optionsFor(_roundIndex, 1);
      });
      await _speakQuestion();
    } else if (_hintLevel == 1) {
      await Companion.instance.say('rephrase_retry');
      setState(() {
        _hintLevel = 2;
        _shownOptions = _optionsFor(_roundIndex, 2);
      });
      await _speakQuestion();
    } else {
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
    if (isNewGame && await LocalStore().awardBadgeIfNew(widget.profile.id, BadgeType.triedNewGame)) {
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

    AudioCueService.instance.play('session_complete');
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
        title: const Text('That was lovely! 🎉'),
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
                children: newBadges.map((b) => Chip(label: Text('${b.emoji} ${b.label}'))).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Home'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _roundIndex = 0;
                _hintLevel = 0;
                _rounds.shuffle(Random());
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remember With Me'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CompanionWidget(
                    expression: CompanionExpression.neutral,
                    size: 130,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Getting your memories ready…',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
            )
          : _rounds.isEmpty
              ? _buildEmptyState(context)
              : _buildGame(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💬', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            const Text(
              "We're still getting to know each other!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              "Once a caregiver notes down a memory or two you've shared, "
              "I'll turn them into a little game just for you.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: Colors.grey),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Play another game'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGame(BuildContext context) {
    final r = _rounds[_roundIndex];
    final text = _hintLevel == 0 ? r.baseText : r.functionalText;

    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('💭', style: TextStyle(fontSize: 88)),
                const SizedBox(height: 16),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
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
                      final isCorrect = opt == r.fact.value;
                      final highlight = _highlightCorrect && isCorrect;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: highlight ? AppColors.accent.withValues(alpha: 0.25) : Colors.white,
                          border: Border.all(
                            color: highlight
                                ? AppColors.accent
                                : AppColors.primary.withValues(alpha: 0.25),
                            width: highlight ? 3 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: highlight
                                  ? AppColors.accent.withValues(alpha: 0.4)
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
                                textAlign: TextAlign.center,
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
        AnimatedOpacity(
          opacity: _interrupted ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: const Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CompanionCorner(size: 48),
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
    );
  }
}
