import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Facial/emotional expression the companion shows. Chosen based on
/// the *situation* (greeting, question, right/wrong answer, etc.)
/// rather than raw text, per the mapping in the design brief.
enum CompanionExpression {
  neutral,
  happy, // greeting: smile + wave
  thinking, // asking a question: head tilt
  excited, // correct answer
  encouraging, // wrong answer: gentle, not scolding
  calm, // user seems confused: soften, slow down
  celebrating, // game completed
}

/// Coarse mouth shape used for lip-sync while audio is playing.
/// Deliberately simple (no phoneme timing) — cycling between these
/// every 100-150ms while TTS speaks reads as "talking" in a demo.
enum MouthState { closed, openSmall, openMedium, openLarge }

/// Central state for the companion character. A single instance is
/// shared app-wide (see [Companion] singleton) so any screen —
/// Home, the Game screen, the dedicated chat screen — can make the
/// character react, and any visible [CompanionCharacter] widget will
/// repaint immediately via ChangeNotifier.
class CompanionController extends ChangeNotifier {
  CompanionExpression expression = CompanionExpression.neutral;
  MouthState mouth = MouthState.closed;
  bool isSpeaking = false;
  bool wave = false;
  bool armsUp = false;
  double headTilt = 0; // radians, extra tilt on top of idle sway

  final _rand = Random();
  Timer? _mouthTimer;
  Timer? _gestureTimer;

  void setExpression(CompanionExpression exp, {bool triggerWave = false, bool triggerArmsUp = false}) {
    expression = exp;
    headTilt = exp == CompanionExpression.thinking ? -0.18 : 0;
    armsUp = triggerArmsUp || exp == CompanionExpression.celebrating;
    if (triggerWave || exp == CompanionExpression.happy) {
      _pulseWave();
    }
    notifyListeners();
  }

  void _pulseWave() {
    _gestureTimer?.cancel();
    wave = true;
    notifyListeners();
    _gestureTimer = Timer(const Duration(seconds: 2), () {
      wave = false;
      notifyListeners();
    });
  }

  /// Starts the mouth-state cycling used while TTS audio is playing.
  /// Call [stopMouthLoop] when playback completes.
  void startMouthLoop() {
    isSpeaking = true;
    _mouthTimer?.cancel();
    _mouthTimer = Timer.periodic(const Duration(milliseconds: 130), (_) {
      const states = [
        MouthState.openSmall,
        MouthState.openMedium,
        MouthState.openLarge,
        MouthState.openMedium,
        MouthState.closed,
      ];
      mouth = states[_rand.nextInt(states.length)];
      notifyListeners();
    });
  }

  void stopMouthLoop() {
    _mouthTimer?.cancel();
    isSpeaking = false;
    mouth = MouthState.closed;
    notifyListeners();
  }

  @override
  void dispose() {
    _mouthTimer?.cancel();
    _gestureTimer?.cancel();
    super.dispose();
  }
}
