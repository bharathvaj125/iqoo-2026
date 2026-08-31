import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smriti/core/local_db/alert_store.dart';
import 'package:smriti/core/local_db/local_store.dart';
import 'package:smriti/core/models/patient.dart';
import 'package:smriti/core/models/session.dart';

enum SyncState { queued, syncing, synced }

class OutboxEntry {
  final String id;
  final String description;
  SyncState state;

  OutboxEntry({required this.id, required this.description, this.state = SyncState.queued});

  Map<String, dynamic> toJson() => {'id': id, 'description': description, 'state': state.name};

  factory OutboxEntry.fromJson(Map<String, dynamic> json) => OutboxEntry(
        id: json['id'] as String,
        description: json['description'] as String,
        // Anything mid-sync when the app closed is neither synced nor safely
        // resumable as "syncing" — treat it as still queued on reload.
        state: json['state'] == 'synced' ? SyncState.synced : SyncState.queued,
      );
}

/// Attendance over a window, derived from real session records rather than stored
/// counters — the caregiver digest reads this so both modules can't drift apart.
class AttendanceStats {
  final int attended;
  final int missed;

  const AttendanceStats({required this.attended, required this.missed});

  int get scheduled => attended + missed;
}

/// Local-first repository for the ASHA module. Persists via [LocalStore] (see that class
/// for why it's shared_preferences today, not sqflite) so session logs, patient rosters,
/// and the sync outbox all survive an app restart — this mirrors "SQLite is the source of
/// truth while offline, not a cache" from the tech-stack doc, just backed by a different
/// local store for now.
class AshaRepository {
  AshaRepository._internal();

  static final AshaRepository instance = AshaRepository._internal();

  static const ashaId = 'asha-demo-1';

  static const _patientsKey = 'asha_patients_v2';
  static const _sessionsKey = 'asha_sessions_v2';
  static const _responsesKey = 'asha_responses_v2';
  static const _outboxKey = 'asha_outbox_v2';

  final List<Patient> _patients = [];
  final List<CareSession> _sessions = [];
  final List<ResponseRecord> _responseRecords = [];
  final List<OutboxEntry> outbox = [];

  bool _loaded = false;

  final _changes = StreamController<void>.broadcast();
  Stream<void> get onChange => _changes.stream;

  List<Patient> get patients => List.unmodifiable(_patients);

  List<CareSession> get allSessions => List.unmodifiable(_sessions);

  /// Only today's sessions — the panel is called "Today's Sessions" and an ASHA opening
  /// it next week should not be handed last week's list to scroll past.
  List<CareSession> get sessionsToday {
    final now = DateTime.now();
    return _sessions.where((s) => _isSameDay(s.scheduledTime, now)).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  static bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Call once at app startup, before reading anything else off this repository.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    await AlertStore.instance.load();

    final store = LocalStore.instance;
    if (!await store.hasKey(_patientsKey)) {
      _seedDemoData();
      await _persistAll();
      return;
    }

    final patientJson = await store.readList(_patientsKey);
    final sessionJson = await store.readList(_sessionsKey);
    final responseJson = await store.readList(_responsesKey);
    final outboxJson = await store.readList(_outboxKey);

    _patients.addAll(patientJson.map(Patient.fromLocalJson));
    _sessions.addAll(sessionJson.map(CareSession.fromLocalJson));
    _responseRecords.addAll(responseJson.map(ResponseRecord.fromJson));
    outbox.addAll(outboxJson.map(OutboxEntry.fromJson));
  }

  void _seedDemoData() {
    _patients.addAll([
      const Patient(
        id: 'p1',
        name: 'Chubaimla Ao',
        language: 'Nagamese',
        assignedAshaId: ashaId,
        age: 74,
        primaryCaregiverId: 'caregiver-demo-1',
        baselineReactionTimeMs: 2400,
        baselineErrorRate: 18,
        baselineHintDependence: 25,
      ),
      const Patient(
        id: 'p2',
        name: 'Ibemhal Devi',
        language: 'Meitei',
        assignedAshaId: ashaId,
        age: 68,
        baselineReactionTimeMs: 1900,
        baselineErrorRate: 12,
        baselineHintDependence: 15,
      ),
      // Deliberately left without a baseline so the onboarding path is visible in the UI.
      const Patient(id: 'p3', name: 'Wanpen Marak', language: 'Garo', assignedAshaId: ashaId, age: 79),
    ]);

    final now = DateTime.now();
    _sessions.addAll([
      CareSession(
        id: 's1',
        type: SessionType.group,
        conductedBy: ConductedBy.ashaSession,
        ashaId: ashaId,
        scheduledTime: DateTime(now.year, now.month, now.day, 10, 0),
        status: SessionStatus.scheduled,
        patientIds: const ['p1', 'p2', 'p3'],
      ),
      CareSession(
        id: 's2',
        type: SessionType.outreach,
        conductedBy: ConductedBy.ashaSession,
        ashaId: ashaId,
        scheduledTime: DateTime(now.year, now.month, now.day, 15, 30),
        status: SessionStatus.scheduled,
        patientIds: const ['p3'],
      ),
    ]);
  }

  Patient patientById(String id) => _patients.firstWhere((p) => p.id == id);

  CareSession? sessionById(String id) {
    final index = _sessions.indexWhere((s) => s.id == id);
    return index == -1 ? null : _sessions[index];
  }

  // ---------------------------------------------------------------- onboarding

  /// Onboarding capture. The baseline readings taken here are what every later session
  /// is compared against (novelty claim #3 — every elder is her own control), so a
  /// patient without one is deliberately surfaced as "baseline not captured" rather
  /// than silently scored against nothing.
  Future<Patient> addPatient({
    required String name,
    required String language,
    int? age,
    int? baselineReactionTimeMs,
    int? baselineErrorRate,
    int? baselineHintDependence,
  }) async {
    final patient = Patient(
      id: 'p-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      language: language,
      assignedAshaId: ashaId,
      age: age,
      baselineReactionTimeMs: baselineReactionTimeMs,
      baselineErrorRate: baselineErrorRate,
      baselineHintDependence: baselineHintDependence,
    );
    _patients.add(patient);
    _queueForSync(
      baselineReactionTimeMs == null
          ? 'New patient onboarded · ${patient.name}'
          : 'New patient onboarded with baseline · ${patient.name}',
    );
    await _persistAll();
    _changes.add(null);
    return patient;
  }

  /// Lets an ASHA capture (or re-capture) a baseline for someone onboarded without one.
  Future<void> captureBaseline({
    required String patientId,
    required int reactionTimeMs,
    required int errorRate,
    required int hintDependence,
  }) async {
    final index = _patients.indexWhere((p) => p.id == patientId);
    if (index == -1) return;
    _patients[index] = _patients[index].copyWith(
      baselineReactionTimeMs: reactionTimeMs,
      baselineErrorRate: errorRate,
      baselineHintDependence: hintDependence,
      trendFlag: _patients[index].trendFlag,
    );
    _queueForSync('Baseline captured · ${_patients[index].name}');
    await _persistAll();
    _changes.add(null);
  }

  // ------------------------------------------------------------------ sessions

  Future<void> createSession({
    required SessionType type,
    required List<String> patientIds,
    required DateTime scheduledTime,
  }) async {
    final session = CareSession(
      id: 's-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      conductedBy: ConductedBy.ashaSession,
      ashaId: ashaId,
      scheduledTime: scheduledTime,
      status: SessionStatus.scheduled,
      patientIds: patientIds,
    );
    _sessions.add(session);
    _queueForSync('New ${type.name} session · ${patientIds.length} patient(s)');
    await _persistAll();
    _changes.add(null);
  }

  /// Solo play the elder did at home on her own, synced down from the patient module
  /// rather than facilitated by the ASHA. Recorded so it shows in her history, but held
  /// apart from assisted rounds everywhere it would otherwise distort scoring.
  Future<CareSession> recordIndependentSession({
    required String patientId,
    required DateTime playedAt,
  }) async {
    final session = CareSession(
      id: 'solo-${DateTime.now().millisecondsSinceEpoch}',
      type: SessionType.solo,
      conductedBy: ConductedBy.independent,
      scheduledTime: playedAt,
      status: SessionStatus.completed,
      patientIds: [patientId],
    );
    _sessions.add(session);
    await _persistAll();
    _changes.add(null);
    return session;
  }

  Future<void> startSession(String sessionId) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;
    _sessions[index] = _sessions[index].copyWith(status: SessionStatus.inProgress);
    await _persistAll();
    _changes.add(null);
  }

  /// Marks the session complete and re-evaluates each participant's trend against her
  /// own baseline.
  Future<void> completeSession(String sessionId) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;
    final session = _sessions[index];
    _sessions[index] = session.copyWith(status: SessionStatus.completed);

    for (final patientId in session.patientIds) {
      await _refreshTrendFlag(patientId);
    }

    _queueForSync('Completed ${session.type.name} session · ${session.patientIds.length} patient(s)');
    await _persistAll();
    _changes.add(null);
  }

  /// An elder who didn't turn up. Feeds the roster's missed count and the caregiver's
  /// attendance figures, both of which were previously fixed numbers.
  Future<void> markSessionMissed(String sessionId) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;
    final session = _sessions[index];
    _sessions[index] = session.copyWith(status: SessionStatus.missed);
    _queueForSync('Missed ${session.type.name} session · ${session.patientIds.length} patient(s)');
    await _persistAll();
    _changes.add(null);
  }

  // ------------------------------------------------------------------ scoring

  /// Assisted and unassisted performance are not comparable — the ASHA spec is explicit
  /// that `conducted_by` exists precisely so the two are never pooled. Trend scoring
  /// therefore only ever looks at ASHA-assisted rounds.
  List<ResponseRecord> _assistedResponses(String patientId) {
    final assistedSessionIds = _sessions
        .where((s) => s.conductedBy == ConductedBy.ashaSession)
        .map((s) => s.id)
        .toSet();
    return _responseRecords
        .where((r) => r.patientId == patientId && assistedSessionIds.contains(r.sessionId))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static int _hintDependencePercent(List<ResponseRecord> records) {
    if (records.isEmpty) return 0;
    final needingHelp = records.where((r) => r.marking != ResponseMarking.independent).length;
    return ((needingHelp / records.length) * 100).round();
  }

  /// Own-baseline drift, never population norms. Compares the patient's recent assisted
  /// rounds against the hint-dependence captured at her own onboarding; where no baseline
  /// was captured, falls back to comparing her recent rounds against her own earlier
  /// rounds. Produces a trend statement routed for review — never a diagnosis.
  Future<void> _refreshTrendFlag(String patientId) async {
    final patientIndex = _patients.indexWhere((p) => p.id == patientId);
    if (patientIndex == -1) return;
    final patient = _patients[patientIndex];

    final assisted = _assistedResponses(patientId);
    const window = 6;
    // Not enough signal yet — say nothing rather than guess from two data points.
    if (assisted.length < window) return;

    final recent = assisted.sublist(assisted.length - window);
    final recentDependence = _hintDependencePercent(recent);

    final int? reference;
    final String referenceLabel;
    if (patient.baselineHintDependence != null) {
      reference = patient.baselineHintDependence;
      referenceLabel = 'her onboarding baseline';
    } else if (assisted.length >= window * 2) {
      reference = _hintDependencePercent(assisted.sublist(assisted.length - window * 2, assisted.length - window));
      referenceLabel = 'her own earlier sessions';
    } else {
      reference = null;
      referenceLabel = '';
    }

    if (reference == null) {
      _patients[patientIndex] = patient.copyWith(trendFlag: null);
      return;
    }

    // Percentage points above her own reference before it's worth anyone's attention.
    const driftThreshold = 20;
    final drift = recentDependence - reference;

    if (drift >= driftThreshold) {
      final message = 'Needed a hint or gave no response in $recentDependence% of her last '
          '$window assisted rounds, against $reference% at $referenceLabel. '
          'Worth reviewing with her.';
      _patients[patientIndex] = patient.copyWith(trendFlag: message);
      await AlertStore.instance.raise(
        patientId: patient.id,
        patientName: patient.name,
        message: message,
      );
    } else {
      _patients[patientIndex] = patient.copyWith(trendFlag: null);
      await AlertStore.instance.clearOpenFor(patient.id);
    }
  }

  Future<void> recordResponse(ResponseRecord record) async {
    _responseRecords.add(record);
    _queueForSync(
      '${patientById(record.patientId).name} · round ${record.roundNumber} · ${record.marking.name}',
    );
    await _persistAll();
    _changes.add(null);
  }

  List<ResponseRecord> responsesForPatient(String patientId) =>
      _responseRecords.where((r) => r.patientId == patientId).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  List<ResponseRecord> responsesForSession(String sessionId) =>
      _responseRecords.where((r) => r.sessionId == sessionId).toList();

  /// Sessions this patient was scheduled for that she didn't attend. Derived, not stored —
  /// a counter that has to be kept in step by hand is a counter that goes wrong.
  int missedSessionCountFor(String patientId) => _sessions
      .where((s) => s.status == SessionStatus.missed && s.patientIds.contains(patientId))
      .length;

  /// Attendance over the trailing [days], for the caregiver dashboard and digest.
  AttendanceStats attendanceFor(String patientId, {int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final relevant = _sessions.where(
      (s) => s.patientIds.contains(patientId) && s.scheduledTime.isAfter(cutoff),
    );
    return AttendanceStats(
      attended: relevant.where((s) => s.status == SessionStatus.completed).length,
      missed: relevant.where((s) => s.status == SessionStatus.missed).length,
    );
  }

  // ---------------------------------------------------------------------- sync

  void _queueForSync(String description) {
    outbox.add(OutboxEntry(id: '${DateTime.now().microsecondsSinceEpoch}', description: description));
  }

  /// Simulates "reconnect and watch the queue drain to zero" — the demo behavior called
  /// out explicitly in the ASHA module spec.
  Future<void> drainOutbox() async {
    final pending = outbox.where((e) => e.state == SyncState.queued).toList();
    for (final entry in pending) {
      entry.state = SyncState.syncing;
      _changes.add(null);
      await Future.delayed(const Duration(milliseconds: 350));
      entry.state = SyncState.synced;
      await _persistAll();
      _changes.add(null);
    }
  }

  /// Successfully-synced rows have no reason to sit on a field device forever; clearing
  /// them keeps the outbox readable as "what still needs to leave this tablet".
  Future<void> clearSyncedEntries() async {
    outbox.removeWhere((e) => e.state == SyncState.synced);
    await _persistAll();
    _changes.add(null);
  }

  Future<void> _persistAll() async {
    final store = LocalStore.instance;
    await Future.wait([
      store.writeList(_patientsKey, _patients.map((p) => p.toLocalJson()).toList()),
      store.writeList(_sessionsKey, _sessions.map((s) => s.toLocalJson()).toList()),
      store.writeList(_responsesKey, _responseRecords.map((r) => r.toJson()).toList()),
      store.writeList(_outboxKey, outbox.map((e) => e.toJson()).toList()),
    ]);
  }

  /// Drops in-memory state so a test can [load] a fresh singleton against clean storage.
  @visibleForTesting
  void resetForTest() {
    _patients.clear();
    _sessions.clear();
    _responseRecords.clear();
    outbox.clear();
    _loaded = false;
  }

  void dispose() => _changes.close();
}
