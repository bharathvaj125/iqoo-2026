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
      CompanionExpression.encouraging,
    ),
    'question': CompanionReply(
      'Do you remember what we did yesterday? Take your time.',
      CompanionExpression.listening,
    ),
    'correct': CompanionReply(
      "Wah! That's correct! You're doing so well!",
      CompanionExpression.encouraging,
    ),
    'wrong': CompanionReply(
      "That's okay, let's try that one again together.",
      CompanionExpression.gentle,
    ),
    'memory_exercise': CompanionReply(
      "Let's use our memory now. Look carefully and take your time.",
      CompanionExpression.listening,
    ),
    'user_confused': CompanionReply(
      "It's alright, no hurry at all. I'm right here with you.",
      CompanionExpression.gentle,
    ),
    'game_completed': CompanionReply(
      "Hooray! You finished the game! I'm so proud of you!",
      CompanionExpression.encouraging,
    ),
    'reminder': CompanionReply(
      "Aita, it's time for your medicine and a glass of water.",
      CompanionExpression.gentle,
    ),
    'who_are_you': CompanionReply(
      "Hi! I'm your little memory companion. Let's play a game together!",
      CompanionExpression.encouraging,
    ),

    // --- Comfort-building intro (spec: framed as playing/chatting,
    // never as a test) ---
    'comfort_intro_1': CompanionReply(
      "Hello! I'm so happy you're here today.",
      CompanionExpression.encouraging,
    ),
    'comfort_intro_2': CompanionReply(
      "We're just going to play and chat together for a little while, "
          'nice and slow, no hurry at all.',
      CompanionExpression.gentle,
    ),
    'comfort_intro_3': CompanionReply(
      "Whenever you're ready, tap the button and let's begin!",
      CompanionExpression.encouraging,
    ),

    // --- Rephrase ladder acknowledgements (never "wrong") ---
    'rephrase_soft': CompanionReply(
      "Let's look again, take your time.",
      CompanionExpression.gentle,
    ),
    'rephrase_retry': CompanionReply(
      "Almost — let's try this one.",
      CompanionExpression.gentle,
    ),
    'rephrase_highlight': CompanionReply(
      "Here, look right here — that's the one.",
      CompanionExpression.gentle,
    ),

    // --- Reminder interrupt / resume ---
    'reminder_task_mode': CompanionReply(
      'One moment — I have something important to tell you.',
      CompanionExpression.gentle,
    ),
    'reminder_ack_thanks': CompanionReply(
      "Thank you! Let's get back to our game.",
      CompanionExpression.encouraging,
    ),

    // --- Streak language (never scolding on a broken streak) ---
    'streak_continue': CompanionReply(
      "Wonderful — you're keeping your streak going!",
      CompanionExpression.encouraging,
    ),
    'streak_reset': CompanionReply(
      "That's alright — let's start a new one today!",
      CompanionExpression.encouraging,
    ),
    'badge_earned': CompanionReply(
      'You earned a little star for that — well done!',
      CompanionExpression.encouraging,
    ),

    // --- Session end ---
    'session_end': CompanionReply(
      'That was lovely spending time with you today. See you again soon!',
      CompanionExpression.encouraging,
    ),

    'resume_game': CompanionReply(
      "Now, where were we… let's continue!",
      CompanionExpression.encouraging,
    ),

    // --- Daily Living Guidance ---
    'daily_living_praise': CompanionReply(
      'Wonderful, thank you for taking care of yourself!',
      CompanionExpression.encouraging,
    ),
    'daily_living_gentle': CompanionReply(
      "That's alright — maybe next time. I'll remind you again later.",
      CompanionExpression.gentle,
    ),

    // --- Personalization loop (Phase 2 — Personal Fact Bank) ---
    'casual_fact_prompt': CompanionReply(
      'Before we play, tell me something — I love hearing about your life.',
      CompanionExpression.encouraging,
    ),
    'fact_saved_thanks': CompanionReply(
      "Thank you for sharing that with me! I'll remember it.",
      CompanionExpression.encouraging,
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
          "I'm happy today! How are you feeling?", CompanionExpression.encouraging);
    }
    if (lower.contains('game') || lower.contains('play')) {
      return const CompanionReply(
          "Yes! Let's go play a memory game together!", CompanionExpression.encouraging);
    }
    if (lower.contains('medicine') || lower.contains('water')) {
      return forSituation('reminder');
    }
    if (lower.trim().isEmpty) {
      return forSituation('user_confused');
    }
    return const CompanionReply(
        "That's nice! Tell me more, I'm listening.", CompanionExpression.gentle);
  }
}
