import 'package:flutter_tts/flutter_tts.dart';
import 'companion_controller.dart';

/// Wraps flutter_tts and drives the companion's mouth-state loop
/// while audio plays, matching the flow in the brief:
///   Text -> Text-to-Speech -> character speaks, mouth animates.
///
/// This is the seam to swap in a real AI response later: replace
/// [CompanionBrain]'s canned replies with a call to your backend's
/// Companion Dialogue Service, then still pass the resulting text
/// into [speak] unchanged.
class TtsService {
  TtsService._internal();
  static final TtsService instance = TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _tts.setLanguage('en-IN'); // Indian English voice where available
    // 0.42 read as a crawl in practice — still a touch slower than the 0.5
    // most platforms treat as "normal", which is the elder-friendly part.
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.15); // slightly higher, child-like pitch
    await _tts.setVolume(1.0);
    _initialized = true;
  }

  /// Speaks [text] while cycling the given [controller]'s mouth state.
  /// Falls back gracefully (still animates mouth for an estimated
  /// duration) if the TTS engine/plugin isn't available on this
  /// platform — useful when demoing on web/desktop without TTS.
  Future<void> speak(String text, CompanionController controller) async {
    await _ensureInit();

    bool completed = false;
    _tts.setCompletionHandler(() {
      completed = true;
    });
    _tts.setErrorHandler((msg) {
      completed = true;
    });

    try {
      final result = await _tts.speak(text);
      if (result != 1) {
        await Future.delayed(_estimateDuration(text));
      }
    } catch (_) {
      await Future.delayed(_estimateDuration(text));
    }
  }

  Duration _estimateDuration(String text) {
    // Rough: ~150ms per word at a slow, elder-friendly pace.
    final words = text.split(RegExp(r'\s+')).length;
    return Duration(milliseconds: (words * 350).clamp(800, 12000));
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
