import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient_models.dart';

/// Offline-first local storage wrapper.
/// In the real product this maps to the SQLite layer shown in the
/// Technical Approach slide (offline/local store, syncs to Postgres
/// via Firebase whenever a connection appears). SharedPreferences is
/// used here only as a lightweight stand-in for the prototype.
class LocalStore {
  static final LocalStore _instance = LocalStore._internal();
  factory LocalStore() => _instance;
  LocalStore._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ---------- Profile ----------
  Future<void> saveActiveProfile(ElderProfile profile) async {
    await init();
    await _prefs!.setString('active_profile', jsonEncode(profile.toJson()));
  }

  Future<ElderProfile?> getActiveProfile() async {
    await init();
    final raw = _prefs!.getString('active_profile');
    if (raw == null) return null;
    return ElderProfile.fromJson(jsonDecode(raw));
  }

  // ---------- Daily goal (family-set task, not a score) ----------
  Future<void> saveDailyGoal(String goal) async {
    await init();
    await _prefs!.setString('daily_goal', goal);
  }

  Future<String> getDailyGoal() async {
    await init();
    return _prefs!.getString('daily_goal') ?? 'Water the tulsi plant today';
  }

  // ---------- Game session logs (queued for sync) ----------
  Future<void> logGameSession(Map<String, dynamic> session) async {
    await init();
    final list = _prefs!.getStringList('pending_sync_sessions') ?? [];
    list.add(jsonEncode(session));
    await _prefs!.setStringList('pending_sync_sessions', list);
  }

  Future<List<Map<String, dynamic>>> getPendingSessions() async {
    await init();
    final list = _prefs!.getStringList('pending_sync_sessions') ?? [];
    return list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  Future<void> clearPendingSessions() async {
    await init();
    await _prefs!.remove('pending_sync_sessions');
  }

  // ---------- Adaptive difficulty (per elder, on-device) ----------
  Future<void> saveDifficulty(String elderId, int level) async {
    await init();
    await _prefs!.setInt('difficulty_$elderId', level);
  }

  Future<int> getDifficulty(String elderId) async {
    await init();
    return _prefs!.getInt('difficulty_$elderId') ?? 2; // 1-5 scale
  }

  // ---------- Streak / last played (for the "2-day drop" wellness signal) ----------
  Future<void> saveLastPlayed(DateTime dt) async {
    await init();
    await _prefs!.setString('last_played', dt.toIso8601String());
  }

  Future<DateTime?> getLastPlayed() async {
    await init();
    final raw = _prefs!.getString('last_played');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  // ---------- Comfort-building intro (shown once per calendar day) ----------
  Future<bool> hasSeenComfortIntroToday() async {
    await init();
    final raw = _prefs!.getString('comfort_intro_last_shown');
    if (raw == null) return false;
    final last = DateTime.tryParse(raw);
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year && last.month == now.month && last.day == now.day;
  }

  Future<void> markComfortIntroShownToday() async {
    await init();
    await _prefs!.setString('comfort_intro_last_shown', DateTime.now().toIso8601String());
  }

  // ---------- Games tried (for the "Tried a New Game" badge) ----------
  Future<Set<String>> getGamesTried() async {
    await init();
    return (_prefs!.getStringList('games_tried') ?? []).toSet();
  }

  /// Returns true the first time a given [gameModule] is recorded.
  Future<bool> recordGameTried(String gameModule) async {
    await init();
    final tried = await getGamesTried();
    final isNew = !tried.contains(gameModule);
    tried.add(gameModule);
    await _prefs!.setStringList('games_tried', tried.toList());
    return isNew;
  }

  // ---------- Streak ----------
  Future<Streak> getStreak(String patientId) async {
    await init();
    final raw = _prefs!.getString('streak_$patientId');
    if (raw == null) return Streak(patientId: patientId);
    return Streak.fromJson(jsonDecode(raw));
  }

  Future<void> _saveStreak(Streak s) async {
    await init();
    await _prefs!.setString('streak_${s.patientId}', jsonEncode(s.toJson()));
  }

  /// Call once per completed session. Returns the updated streak so the
  /// caller can decide whether a streak-milestone badge was just reached.
  Future<Streak> recordSessionCompleted(String patientId) async {
    final streak = await getStreak(patientId);
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    if (streak.lastCompletedDate != null) {
      final last = streak.lastCompletedDate!;
      final lastDateOnly = DateTime(last.year, last.month, last.day);
      final dayGap = todayDateOnly.difference(lastDateOnly).inDays;
      if (dayGap == 0) {
        // Already logged today — no change.
        return streak;
      } else if (dayGap == 1) {
        streak.currentStreakDays += 1;
      } else {
        // Streak broken — start a fresh one today. Companion language
        // around this must stay warm; see CompanionBrain's 'streak_reset'.
        streak.currentStreakDays = 1;
      }
    } else {
      streak.currentStreakDays = 1;
    }

    if (streak.currentStreakDays > streak.longestStreak) {
      streak.longestStreak = streak.currentStreakDays;
    }
    streak.lastCompletedDate = today;
    await _saveStreak(streak);
    return streak;
  }

  // ---------- Reward badges ----------
  Future<List<RewardBadge>> getBadges(String patientId) async {
    await init();
    final list = _prefs!.getStringList('badges_$patientId') ?? [];
    return list.map((e) => RewardBadge.fromJson(jsonDecode(e))).toList();
  }

  /// Awards [type] if the patient doesn't already have it. Returns true if
  /// newly awarded (so the UI can show a celebratory moment only once).
  Future<bool> awardBadgeIfNew(String patientId, BadgeType type) async {
    await init();
    final badges = await getBadges(patientId);
    if (badges.any((b) => b.badgeType == type)) return false;
    badges.add(RewardBadge(badgeType: type, earnedAt: DateTime.now()));
    await _prefs!.setStringList(
      'badges_$patientId',
      badges.map((b) => jsonEncode(b.toJson())).toList(),
    );
    return true;
  }

  // ---------- Response records (independent / hint / no-response) ----------
  Future<void> logResponseRecord(ResponseRecord record) async {
    await init();
    final list = _prefs!.getStringList('response_records') ?? [];
    list.add(jsonEncode(record.toJson()));
    await _prefs!.setStringList('response_records', list);
  }

  Future<List<ResponseRecord>> getResponseRecords() async {
    await init();
    final list = _prefs!.getStringList('response_records') ?? [];
    return list.map((e) => ResponseRecord.fromJson(jsonDecode(e))).toList();
  }

  // ---------- Game session snapshot (pause/resume on reminder interrupt) ----------
  Future<void> saveGameSnapshot(GameSessionSnapshot snap) async {
    await init();
    await _prefs!.setString('game_snapshot_${snap.gameModule}', jsonEncode(snap.toJson()));
  }

  Future<GameSessionSnapshot?> getGameSnapshot(String gameModule) async {
    await init();
    final raw = _prefs!.getString('game_snapshot_$gameModule');
    if (raw == null) return null;
    return GameSessionSnapshot.fromJson(jsonDecode(raw));
  }

  Future<void> clearGameSnapshot(String gameModule) async {
    await init();
    await _prefs!.remove('game_snapshot_$gameModule');
  }

  // ---------- Reminder acknowledgements ----------
  Future<void> logReminderAck(ReminderAck ack) async {
    await init();
    final list = _prefs!.getStringList('reminder_acks') ?? [];
    list.add(jsonEncode(ack.toJson()));
    await _prefs!.setStringList('reminder_acks', list);
  }

  Future<List<ReminderAck>> getReminderAcks() async {
    await init();
    final list = _prefs!.getStringList('reminder_acks') ?? [];
    return list.map((e) => ReminderAck.fromJson(jsonDecode(e))).toList();
  }

  // ---------- Personal Fact Bank (Phase 2 — personalization loop) ----------
  // Facilitator-assisted only for this build: an ASHA/caregiver enters the
  // fact via the short structured form. Direct voice capture (Bhashini/
  // AI4Bharat, 2-3 demo languages) is additive per the spec and not built
  // here — it would plug in ahead of the same `savePersonalFact` call.
  Future<List<PersonalFact>> getPersonalFacts(String patientId) async {
    await init();
    final list = _prefs!.getStringList('personal_facts_$patientId') ?? [];
    return list.map((e) => PersonalFact.fromJson(jsonDecode(e))).toList();
  }

  Future<void> savePersonalFact(PersonalFact fact) async {
    await init();
    final facts = await getPersonalFacts(fact.patientId);
    facts.add(fact);
    await _prefs!.setStringList(
      'personal_facts_${fact.patientId}',
      facts.map((f) => jsonEncode(f.toJson())).toList(),
    );
  }

  Future<void> deletePersonalFact(String patientId, String factId) async {
    await init();
    final facts = await getPersonalFacts(patientId);
    facts.removeWhere((f) => f.id == factId);
    await _prefs!.setStringList(
      'personal_facts_$patientId',
      facts.map((f) => jsonEncode(f.toJson())).toList(),
    );
  }

  /// Tracks the last time the companion slipped a casual "tell me about
  /// yourself" prompt in between games, so it doesn't ask every round —
  /// spec: "a casual companion prompt slipped between games", not a form
  /// on every screen.
  Future<bool> shouldOfferCasualFactPrompt() async {
    await init();
    final raw = _prefs!.getString('last_casual_fact_prompt');
    if (raw == null) return true;
    final last = DateTime.tryParse(raw);
    if (last == null) return true;
    return DateTime.now().difference(last).inHours >= 20;
  }

  Future<void> markCasualFactPromptShown() async {
    await init();
    await _prefs!.setString('last_casual_fact_prompt', DateTime.now().toIso8601String());
  }

  // ---------- Daily Living Guidance (Phase 3) ----------
  // Caregiver customization (enable/disable per patient) is stored locally
  // here as a stand-in for the real Caregiver-module setting.
  Future<List<DailyLivingPrompt>> getDailyLivingPrompts() async {
    await init();
    final raw = _prefs!.getStringList('daily_living_prompts');
    if (raw == null) return kDefaultDailyLivingPrompts;
    final saved = raw.map((e) => DailyLivingPrompt.fromJson(jsonDecode(e))).toList();
    // Merge in case new default scenarios were added after the prefs were
    // first written, so upgrades don't silently drop new prompts.
    final savedIds = saved.map((p) => p.id).toSet();
    for (final def in kDefaultDailyLivingPrompts) {
      if (!savedIds.contains(def.id)) saved.add(def);
    }
    return saved;
  }

  Future<void> setDailyLivingPromptEnabled(String promptId, bool enabled) async {
    await init();
    final prompts = await getDailyLivingPrompts();
    final updated = prompts
        .map((p) => p.id == promptId ? p.copyWith(enabled: enabled) : p)
        .toList();
    await _prefs!.setStringList(
      'daily_living_prompts',
      updated.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }

  /// One DLG card per time-of-day bucket per day, so the patient isn't
  /// nagged repeatedly — spec calls these single-step, 10-15s interactions.
  Future<DailyLivingPrompt?> getDueDailyLivingPrompt() async {
    await init();
    final bucket = timeOfDayBucket(DateTime.now());
    final todayKey = 'dlg_shown_${bucket}_${_todayString()}';
    if (_prefs!.getBool(todayKey) == true) return null;
    final prompts = await getDailyLivingPrompts();
    final candidates = prompts.where((p) => p.enabled && p.triggerTimeOfDay == bucket).toList();
    if (candidates.isEmpty) return null;
    candidates.shuffle();
    return candidates.first;
  }

  Future<void> markDailyLivingPromptShown(String bucket) async {
    await init();
    await _prefs!.setBool('dlg_shown_${bucket}_${_todayString()}', true);
  }

  Future<void> logDailyLivingCompletion(String patientId, String promptId, bool didIt) async {
    await init();
    final list = _prefs!.getStringList('dlg_completions') ?? [];
    list.add(jsonEncode({
      'patientId': patientId,
      'promptId': promptId,
      'didIt': didIt,
      'timestamp': DateTime.now().toIso8601String(),
    }));
    await _prefs!.setStringList('dlg_completions', list);
  }

  String _todayString() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }
}

class ElderProfile {
  final String id;
  final String name;
  final String photoAsset; // path or emoji fallback for prototype
  final String language; // e.g. "Assamese", "Khasi", "Manipuri", "English"
  final String state; // NER state, drives cultural motifs/songs

  ElderProfile({
    required this.id,
    required this.name,
    required this.photoAsset,
    required this.language,
    required this.state,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'photoAsset': photoAsset,
        'language': language,
        'state': state,
      };

  factory ElderProfile.fromJson(Map<String, dynamic> j) => ElderProfile(
        id: j['id'],
        name: j['name'],
        photoAsset: j['photoAsset'],
        language: j['language'],
        state: j['state'],
      );
}
