/// Data models backing the Phase 1 core flow from the patient
/// module spec: reminders (with interrupt/resume), daily streaks,
/// effort-based reward badges, and per-question response records with
/// a `hint_level` for the rephrase ladder.
///
/// These are plain JSON-serializable Dart classes stored locally via
/// [LocalStore] for the prototype. Field names intentionally mirror the
/// spec's data-model section so this maps cleanly onto real Postgres
/// tables later without renaming anything.
library patient_models;

/// `reminder` — created on the Caregiver dashboard in the real product;
/// represented locally here so the interrupt/resume flow can be built
/// and demoed without that integration.
class ReminderItem {
  final String id;
  final String title;
  final String category; // medicine | hydration | activity | appointment
  final String timeOfDay; // e.g. "08:00" (24h, local demo scheduling)
  final String? voiceClipUrl; // caregiver's recorded voice clip, if any
  bool acknowledgedToday;
  DateTime? lastFiredAt;
  DateTime? lastAcknowledgedAt;

  ReminderItem({
    required this.id,
    required this.title,
    required this.category,
    required this.timeOfDay,
    this.voiceClipUrl,
    this.acknowledgedToday = false,
    this.lastFiredAt,
    this.lastAcknowledgedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'timeOfDay': timeOfDay,
        'voiceClipUrl': voiceClipUrl,
        'acknowledgedToday': acknowledgedToday,
        'lastFiredAt': lastFiredAt?.toIso8601String(),
        'lastAcknowledgedAt': lastAcknowledgedAt?.toIso8601String(),
      };

  factory ReminderItem.fromJson(Map<String, dynamic> j) => ReminderItem(
        id: j['id'],
        title: j['title'],
        category: j['category'],
        timeOfDay: j['timeOfDay'],
        voiceClipUrl: j['voiceClipUrl'],
        acknowledgedToday: j['acknowledgedToday'] ?? false,
        lastFiredAt: j['lastFiredAt'] != null ? DateTime.tryParse(j['lastFiredAt']) : null,
        lastAcknowledgedAt:
            j['lastAcknowledgedAt'] != null ? DateTime.tryParse(j['lastAcknowledgedAt']) : null,
      );
}

/// `reminder_ack` — written when the patient taps the big "I did it" button.
/// Same shape referenced by the caregiver spec so both dashboards read the
/// same data once integrated.
class ReminderAck {
  final String reminderId;
  final String patientId;
  final DateTime acknowledgedAt;

  ReminderAck({
    required this.reminderId,
    required this.patientId,
    required this.acknowledgedAt,
  });

  Map<String, dynamic> toJson() => {
        'reminderId': reminderId,
        'patientId': patientId,
        'acknowledgedAt': acknowledgedAt.toIso8601String(),
      };

  factory ReminderAck.fromJson(Map<String, dynamic> j) => ReminderAck(
        reminderId: j['reminderId'],
        patientId: j['patientId'],
        acknowledgedAt: DateTime.parse(j['acknowledgedAt']),
      );
}

/// `game_session_state` — pause/resume snapshot. [inProgressState] is a
/// free-form JSON map so each game screen can serialize whatever it needs
/// (revealed cards, current question index, rephrase-ladder step, etc.)
/// without this model needing to know about every game's internals.
class GameSessionSnapshot {
  final String patientId;
  final String gameModule;
  final int roundNumber;
  final Map<String, dynamic> inProgressState;
  final DateTime pausedAt;
  DateTime? resumedAt;

  GameSessionSnapshot({
    required this.patientId,
    required this.gameModule,
    required this.roundNumber,
    required this.inProgressState,
    required this.pausedAt,
    this.resumedAt,
  });

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'gameModule': gameModule,
        'roundNumber': roundNumber,
        'inProgressState': inProgressState,
        'pausedAt': pausedAt.toIso8601String(),
        'resumedAt': resumedAt?.toIso8601String(),
      };

  factory GameSessionSnapshot.fromJson(Map<String, dynamic> j) => GameSessionSnapshot(
        patientId: j['patientId'],
        gameModule: j['gameModule'],
        roundNumber: j['roundNumber'],
        inProgressState: Map<String, dynamic>.from(j['inProgressState']),
        pausedAt: DateTime.parse(j['pausedAt']),
        resumedAt: j['resumedAt'] != null ? DateTime.tryParse(j['resumedAt']) : null,
      );
}

/// `streak` — increments once per calendar day a full session is completed.
class Streak {
  final String patientId;
  int currentStreakDays;
  int longestStreak;
  DateTime? lastCompletedDate;

  Streak({
    required this.patientId,
    this.currentStreakDays = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
  });

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'currentStreakDays': currentStreakDays,
        'longestStreak': longestStreak,
        'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      };

  factory Streak.fromJson(Map<String, dynamic> j) => Streak(
        patientId: j['patientId'],
        currentStreakDays: j['currentStreakDays'] ?? 0,
        longestStreak: j['longestStreak'] ?? 0,
        lastCompletedDate:
            j['lastCompletedDate'] != null ? DateTime.tryParse(j['lastCompletedDate']) : null,
      );
}

/// `reward_badge` — milestone-based, tied to consistency/effort only.
/// Never derived from accuracy or speed (see spec's zero-failure design).
enum BadgeType {
  streak5Day,
  streak10Day,
  triedNewGame,
  finishedToday,
  firstSession,
}

class RewardBadge {
  final BadgeType badgeType;
  final DateTime earnedAt;

  RewardBadge({required this.badgeType, required this.earnedAt});

  Map<String, dynamic> toJson() => {
        'badgeType': badgeType.name,
        'earnedAt': earnedAt.toIso8601String(),
      };

  factory RewardBadge.fromJson(Map<String, dynamic> j) => RewardBadge(
        badgeType: BadgeType.values.firstWhere((b) => b.name == j['badgeType']),
        earnedAt: DateTime.parse(j['earnedAt']),
      );

  String get label {
    switch (badgeType) {
      case BadgeType.streak5Day:
        return '5-Day Streak';
      case BadgeType.streak10Day:
        return '10-Day Streak';
      case BadgeType.triedNewGame:
        return 'Tried a New Game';
      case BadgeType.finishedToday:
        return "Finished Today's Session";
      case BadgeType.firstSession:
        return 'First Session';
    }
  }

  String get emoji {
    switch (badgeType) {
      case BadgeType.streak5Day:
        return '🔥';
      case BadgeType.streak10Day:
        return '🌟';
      case BadgeType.triedNewGame:
        return '🎲';
      case BadgeType.finishedToday:
        return '🎉';
      case BadgeType.firstSession:
        return '🌱';
    }
  }
}

/// Three-way marking from the ASHA spec, extended here with [hintLevel]
/// so the rephrase ladder's granularity is captured, not just a flat
/// independent/hint/no-response marking.
enum ResponseMark { independent, hint, noResponse }

class ResponseRecord {
  final String patientId;
  final String gameModule;
  final String questionId;
  final ResponseMark mark;
  final int hintLevel; // 0 = answered on the first, unmodified question
  final bool fromPersonalFact;
  final DateTime timestamp;

  ResponseRecord({
    required this.patientId,
    required this.gameModule,
    required this.questionId,
    required this.mark,
    this.hintLevel = 0,
    this.fromPersonalFact = false,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'gameModule': gameModule,
        'questionId': questionId,
        'mark': mark.name,
        'hintLevel': hintLevel,
        'fromPersonalFact': fromPersonalFact,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ResponseRecord.fromJson(Map<String, dynamic> j) => ResponseRecord(
        patientId: j['patientId'],
        gameModule: j['gameModule'],
        questionId: j['questionId'],
        mark: ResponseMark.values.firstWhere((m) => m.name == j['mark']),
        hintLevel: j['hintLevel'] ?? 0,
        fromPersonalFact: j['fromPersonalFact'] ?? false,
        timestamp: DateTime.parse(j['timestamp']),
      );
}

/// `personal_fact` — a single captured detail about *this* patient's life,
/// the atomic unit the personalization loop (Phase 2) runs on. Captured
/// facilitator-assisted (ASHA/caregiver short form) for the hackathon;
/// direct voice capture is additive per the spec and not required here.
class PersonalFact {
  final String id;
  final String patientId;
  final String category; // e.g. gift_from_family, hometown, hobby, pet
  final String entity; // e.g. "daughter", "childhood home"
  final String value; // e.g. "jasmine"
  final String source; // facilitator_assisted | voice_capture
  final DateTime capturedAt;
  final double confidence; // 1.0 for facilitator-entered facts

  PersonalFact({
    required this.id,
    required this.patientId,
    required this.category,
    required this.entity,
    required this.value,
    this.source = 'facilitator_assisted',
    required this.capturedAt,
    this.confidence = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'category': category,
        'entity': entity,
        'value': value,
        'source': source,
        'capturedAt': capturedAt.toIso8601String(),
        'confidence': confidence,
      };

  factory PersonalFact.fromJson(Map<String, dynamic> j) => PersonalFact(
        id: j['id'],
        patientId: j['patientId'],
        category: j['category'],
        entity: j['entity'],
        value: j['value'],
        source: j['source'] ?? 'facilitator_assisted',
        capturedAt: DateTime.parse(j['capturedAt']),
        confidence: (j['confidence'] ?? 1.0).toDouble(),
      );
}

/// `daily_living_prompt` — a short, single-step safety/routine nudge.
/// Distinct from caregiver reminders (scheduled, med/hydration/etc.) and
/// from scored gameplay: pure coaching, no scoring, no failure state.
class DailyLivingPrompt {
  final String id;
  final String category; // night_safety | hygiene | mobility | ...
  final String triggerTimeOfDay; // morning | afternoon | evening | night
  final String text;
  final bool isCaregiverCustomized;
  final String? companionVoiceClipUrl;
  final bool enabled;

  const DailyLivingPrompt({
    required this.id,
    required this.category,
    required this.triggerTimeOfDay,
    required this.text,
    this.isCaregiverCustomized = false,
    this.companionVoiceClipUrl,
    this.enabled = true,
  });

  DailyLivingPrompt copyWith({bool? enabled}) => DailyLivingPrompt(
        id: id,
        category: category,
        triggerTimeOfDay: triggerTimeOfDay,
        text: text,
        isCaregiverCustomized: isCaregiverCustomized,
        companionVoiceClipUrl: companionVoiceClipUrl,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'triggerTimeOfDay': triggerTimeOfDay,
        'text': text,
        'isCaregiverCustomized': isCaregiverCustomized,
        'companionVoiceClipUrl': companionVoiceClipUrl,
        'enabled': enabled,
      };

  factory DailyLivingPrompt.fromJson(Map<String, dynamic> j) => DailyLivingPrompt(
        id: j['id'],
        category: j['category'],
        triggerTimeOfDay: j['triggerTimeOfDay'],
        text: j['text'],
        isCaregiverCustomized: j['isCaregiverCustomized'] ?? false,
        companionVoiceClipUrl: j['companionVoiceClipUrl'],
        enabled: j['enabled'] ?? true,
      );
}

/// Fixed set of 5 Daily Living Guidance scenarios for the hackathon demo
/// (spec: "define a short fixed set (3-5 scenarios) rather than trying to
/// cover every ADL"). Night bathroom safety is the spec's own example.
const List<DailyLivingPrompt> kDefaultDailyLivingPrompts = [
  DailyLivingPrompt(
    id: 'night_bathroom_light',
    category: 'night_safety',
    triggerTimeOfDay: 'night',
    text: 'If you get up at night, switch on the light before you walk to '
        'the bathroom.',
  ),
  DailyLivingPrompt(
    id: 'night_water_by_bed',
    category: 'night_safety',
    triggerTimeOfDay: 'night',
    text: "Keep a glass of water by your bed so you don't need to walk far "
        'if you feel thirsty at night.',
  ),
  DailyLivingPrompt(
    id: 'evening_door_lock',
    category: 'mobility',
    triggerTimeOfDay: 'evening',
    text: 'Before you settle in for the evening, check that the front door '
        'is locked.',
  ),
  DailyLivingPrompt(
    id: 'morning_footwear',
    category: 'mobility',
    triggerTimeOfDay: 'morning',
    text: 'Wear your slippers before walking around this morning, so your '
        'feet stay steady.',
  ),
  DailyLivingPrompt(
    id: 'afternoon_hygiene',
    category: 'hygiene',
    triggerTimeOfDay: 'afternoon',
    text: 'Have you washed your hands before your afternoon meal today?',
  ),
];

/// Which fixed time-of-day bucket [now] falls into, for triggering
/// Daily Living Guidance cards (spec: "time-of-day triggered by default").
String timeOfDayBucket(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 12) return 'morning';
  if (h >= 12 && h < 17) return 'afternoon';
  if (h >= 17 && h < 21) return 'evening';
  return 'night';
}
