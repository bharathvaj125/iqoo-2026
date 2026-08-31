import 'companion_controller.dart';

/// One line of companion dialogue plus the expression it should show.
class CompanionReply {
  final String text;
  final CompanionExpression expression;
  const CompanionReply(this.text, this.expression);
}

/// Rule-based responses for the prototype/demo.
///
/// This stands in for the real flow in the brief:
///   User -> Flutter App -> AI generates response -> Text -> TTS
/// For the hackathon, swap [CompanionBrain.forSituation] (or add a
/// new async method) to call your backend's Companion Dialogue
/// Service / an LLM, and feed the returned text into
/// `TtsService.instance.speak(text, controller)` exactly as done here.
class CompanionBrain {
  static const Map<String, CompanionReply> _situations = {
    'greeting': CompanionReply(
      "Hi! I'm your little memory companion. Let's play a game together!",
      CompanionExpression.happy,
    ),
    'question': CompanionReply(
      "Do you remember what we did yesterday? Take your time.",
      CompanionExpression.thinking,
    ),
    'correct': CompanionReply(
      "Wah! That's correct! You're doing so well!",
      CompanionExpression.excited,
    ),
    'wrong': CompanionReply(
      "That's okay, let's try that one again together.",
      CompanionExpression.encouraging,
    ),
    'memory_exercise': CompanionReply(
      "Let's use our memory now. Look carefully and take your time.",
      CompanionExpression.thinking,
    ),
    'user_confused': CompanionReply(
      "It's alright, no hurry at all. I'm right here with you.",
      CompanionExpression.calm,
    ),
    'game_completed': CompanionReply(
      "Hooray! You finished the game! I'm so proud of you!",
      CompanionExpression.celebrating,
    ),
    'reminder': CompanionReply(
      "Aita, it's time for your medicine and a glass of water.",
      CompanionExpression.calm,
    ),
    'who_are_you': CompanionReply(
      "Hi! I'm your little memory companion. Let's play a game together!",
      CompanionExpression.happy,
    ),

    // --- Comfort-building intro (spec: framed as playing/chatting,
    // never as a test) ---
    'comfort_intro_1': CompanionReply(
      "Hello! I'm so happy you're here today.",
      CompanionExpression.happy,
    ),
    'comfort_intro_2': CompanionReply(
      "We're just going to play and chat together for a little while, "
          "nice and slow, no hurry at all.",
      CompanionExpression.calm,
    ),
    'comfort_intro_3': CompanionReply(
      "Whenever you're ready, tap the button and let's begin!",
      CompanionExpression.encouraging,
    ),

    // --- Rephrase ladder acknowledgements (never "wrong") ---
    'rephrase_soft': CompanionReply(
      "Let's look again, take your time.",
      CompanionExpression.encouraging,
    ),
    'rephrase_retry': CompanionReply(
      "Almost — let's try this one.",
      CompanionExpression.encouraging,
    ),
    'rephrase_highlight': CompanionReply(
      "Here, look right here — that's the one.",
      CompanionExpression.calm,
    ),

    // --- Reminder interrupt / resume ---
    'reminder_task_mode': CompanionReply(
      "One moment — I have something important to tell you.",
      CompanionExpression.calm,
    ),
    'reminder_ack_thanks': CompanionReply(
      "Thank you! Let's get back to our game.",
      CompanionExpression.happy,
    ),

    // --- Streak language (never scolding on a broken streak) ---
    'streak_continue': CompanionReply(
      "Wonderful — you're keeping your streak going!",
      CompanionExpression.excited,
    ),
    'streak_reset': CompanionReply(
      "That's alright — let's start a new one today!",
      CompanionExpression.encouraging,
    ),
    'badge_earned': CompanionReply(
      "You earned a little star for that — well done!",
      CompanionExpression.celebrating,
    ),

    // --- Session end ---
    'session_end': CompanionReply(
      "That was lovely spending time with you today. See you again soon!",
      CompanionExpression.happy,
    ),

    'resume_game': CompanionReply(
      "Now, where were we… let's continue!",
      CompanionExpression.happy,
    ),

    // --- Daily Living Guidance ---
    'daily_living_praise': CompanionReply(
      "Wonderful, thank you for taking care of yourself!",
      CompanionExpression.celebrating,
    ),
    'daily_living_gentle': CompanionReply(
      "That's alright — maybe next time. I'll remind you again later.",
      CompanionExpression.calm,
    ),

    // --- Personalization loop (Phase 2 — Personal Fact Bank) ---
    'casual_fact_prompt': CompanionReply(
      "Before we play, tell me something — I love hearing about your life.",
      CompanionExpression.happy,
    ),
    'fact_saved_thanks': CompanionReply(
      "Thank you for sharing that with me! I'll remember it.",
      CompanionExpression.happy,
    ),
    'reminiscence_no_facts_yet': CompanionReply(
      "We're still getting to know each other! Let's play a little more, "
          "and soon I'll ask about you, too.",
      CompanionExpression.encouraging,
    ),
  };

  static CompanionReply forSituation(String key) {
    return _situations[key] ??
        const CompanionReply("Hello! I'm here with you.", CompanionExpression.neutral);
  }

  /// Very small keyword matcher for the free-text demo box, so typing
  /// "who are you" or "how are you" gets a sensible reply without a
  /// real LLM call. Replace with an actual API call when ready.
  static CompanionReply forFreeText(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('who are you')) return forSituation('who_are_you');
    if (lower.contains('how are you')) {
      return const CompanionReply(
          "I'm happy today! How are you feeling?", CompanionExpression.happy);
    }
    if (lower.contains('game') || lower.contains('play')) {
      return const CompanionReply(
          "Yes! Let's go play a memory game together!", CompanionExpression.excited);
    }
    if (lower.contains('medicine') || lower.contains('water')) {
      return forSituation('reminder');
    }
    if (lower.trim().isEmpty) {
      return forSituation('user_confused');
    }
    return const CompanionReply(
        "That's nice! Tell me more, I'm listening.", CompanionExpression.calm);
  }
}
