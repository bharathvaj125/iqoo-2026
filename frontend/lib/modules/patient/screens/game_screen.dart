import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/patient_models.dart';
import '../services/local_store.dart';
import '../services/companion.dart';
import '../services/reminder_service.dart';
import '../services/audio_cue_service.dart';
import 'package:smriti/core/theme.dart';
import '../widgets/reminder_task_overlay.dart';
import '../widgets/companion_corner.dart';
import '../../../widgets/companion_widget.dart';

/// Adaptive CST (Cognitive Stimulation Therapy) game.
/// Demonstrates the "Adaptive Difficulty Engine" from the architecture
/// diagram: grid size (difficulty) is tuned on-device from accuracy
/// and response latency — never shown to the elder as a "score",
/// per the "A Goal, Not a Score" novelty point.
class GameScreen extends StatefulWidget {
  final ElderProfile profile;
  const GameScreen({super.key, required this.profile});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const _module = 'memory_match';

  // Culturally themed icon sets stand in for real photo/audio assets
  // ("Her Language and Culture" / "Tuned to Her Decade").
  final List<String> _iconPool = [
    '🌾', '🐘', '🪈', '🎣', '🛶', '🏞️', '🐄', '🌸', '🥁', '🌙'
  ];

  late int _gridPairs; // difficulty: number of matching pairs
  late List<String> _cards;
  final List<bool> _revealed = [];
  final List<bool> _matched = [];
  int? _firstIndex;
  bool _busy = false;
  int _mistakes = 0;
  late DateTime _startTime;
  Timer? _latencyTimer;
  bool _interrupted = false;

  @override
  void initState() {
    super.initState();
    ReminderService.instance.addListener(_onReminderChange);
    _setup();
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
        roundNumber: 0,
        inProgressState: {
          'cards': _cards,
          'revealed': _revealed,
          'matched': _matched,
          'mistakes': _mistakes,
        },
        pausedAt: DateTime.now(),
      ),
    );
    if (mounted) setState(() => _interrupted = true);
  }

  Future<void> _onReminderAcknowledged() async {
    // Restore from the persisted snapshot so this behaves correctly even
    // if the app were fully backgrounded during the interruption.
    final snap = await LocalStore().getGameSnapshot(_module);
    if (snap != null) {
      setState(() {
        _cards = List<String>.from(snap.inProgressState['cards']);
        _revealed
          ..clear()
          ..addAll(List<bool>.from(snap.inProgressState['revealed']));
        _matched
          ..clear()
          ..addAll(List<bool>.from(snap.inProgressState['matched']));
        _mistakes = snap.inProgressState['mistakes'] ?? _mistakes;
      });
      await LocalStore().clearGameSnapshot(_module);
    }
    await Companion.instance.say('resume_game');
    if (mounted) setState(() => _interrupted = false);
  }

  Future<void> _setup() async {
    final level = await LocalStore().getDifficulty(widget.profile.id);
    // level 1-5 -> 3 to 7 pairs
    _gridPairs = 2 + level.clamp(1, 5);
    final chosen = (_iconPool..shuffle()).take(_gridPairs).toList();
    _cards = [...chosen, ...chosen]..shuffle();
    _revealed
      ..clear()
      ..addAll(List.filled(_cards.length, false));
    _matched
      ..clear()
      ..addAll(List.filled(_cards.length, false));
    _mistakes = 0;
    _startTime = DateTime.now();
    if (mounted) setState(() {});
  }

  Future<void> _onTap(int index) async {
    if (_busy || _revealed[index] || _matched[index]) return;
    setState(() => _revealed[index] = true);

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    _busy = true;
    final first = _firstIndex!;
    if (_cards[first] == _cards[index]) {
      setState(() {
        _matched[first] = true;
        _matched[index] = true;
      });
      AudioCueService.instance.play('correct');
      Companion.instance.say('correct');
    } else {
      _mistakes++;
      AudioCueService.instance.play('miss');
      Companion.instance.say('wrong');
      await Future.delayed(const Duration(milliseconds: 700));
      setState(() {
        _revealed[first] = false;
        _revealed[index] = false;
      });
    }
    _firstIndex = null;
    _busy = false;

    if (_matched.every((m) => m)) {
      await _completeSession();
    }
  }

  Future<void> _completeSession() async {
    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    final accuracy = _gridPairs / (_gridPairs + _mistakes);

    // Adapt difficulty for next session (on-device, silent to the elder).
    int level = await LocalStore().getDifficulty(widget.profile.id);
    if (accuracy > 0.85 && elapsed < _gridPairs * 6) {
      level = (level + 1).clamp(1, 5);
    } else if (accuracy < 0.5) {
      level = (level - 1).clamp(1, 5);
    }
    await LocalStore().saveDifficulty(widget.profile.id, level);
    await LocalStore().saveLastPlayed(DateTime.now());
    await LocalStore().logGameSession({
      'elderId': widget.profile.id,
      'game': 'memory_match',
      'pairs': _gridPairs,
      'mistakes': _mistakes,
      'seconds': elapsed,
      'accuracy': accuracy,
      'timestamp': DateTime.now().toIso8601String(),
    });

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

    AudioCueService.instance.play('session_complete');
    if (!mounted) return;
    await Companion.instance.say('game_completed');
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await Companion.instance.say('session_end');

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Well done! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You matched all the pictures!'),
            const SizedBox(height: 10),
            Text('🔥 Streak: ${streak.currentStreakDays} day'
                '${streak.currentStreakDays == 1 ? '' : 's'}'),
            if (newBadges.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children:
                    newBadges.map((b) => Chip(label: Text('${b.emoji} ${b.label}'))).toList(),
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
              _setup();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _latencyTimer?.cancel();
    ReminderService.instance.removeListener(_onReminderChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = _cards.isEmpty
        ? 2
        : (sqrt(_cards.length).ceil()).clamp(2, 4);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Match'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          _cards.isEmpty
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
                        'Getting your game ready…',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    itemCount: _cards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final show = _revealed[index] || _matched[index];
                      return GestureDetector(
                        onTap: _interrupted ? null : () => _onTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _matched[index]
                                ? AppColors.successAccent.withValues(alpha: 0.18)
                                : (show ? Colors.white : AppColors.primary),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(color: AppColors.cardShadow, blurRadius: 4)
                            ],
                          ),
                          child: Center(
                            child: Text(
                              show ? _cards[index] : '❓',
                              style: const TextStyle(fontSize: 36),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          // Companion Corner — fades out during interruptions since ReminderTaskOverlay has its own companion
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
      ),
    );
  }
}
