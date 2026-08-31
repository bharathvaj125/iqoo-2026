/// Audio cue service stub for non-jarring acoustic feedback in the Patient module.
/// 
/// Real audio assets and Bhashini-synthesized voice cues are handled in Track B.
/// This service provides the exact event hooks called by the gameplay & completion flows.
class AudioCueService {
  AudioCueService._();
  static final AudioCueService instance = AudioCueService._();

  /// Play a soft, non-jarring feedback cue.
  /// Supported cues: 'correct', 'miss', 'session_complete'
  void play(String cue) {
    // TODO(Track B): Connect to local audio assets / Bhashini audio playback
    // e.g. AudioPlayer().play(AssetSource('audio/cues/$cue.mp3'))
  }
}
