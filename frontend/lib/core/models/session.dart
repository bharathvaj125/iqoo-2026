enum SessionType { group, solo, outreach }

enum ConductedBy { ashaSession, independent }

enum SessionStatus { scheduled, inProgress, completed, missed }

/// The three-way marking an ASHA logs for each patient, each round, during a session.
enum ResponseMarking { independent, hint, noResponse }

String sessionTypeToJson(SessionType t) => t.name;

String conductedByToJson(ConductedBy c) => switch (c) {
      ConductedBy.ashaSession => 'asha_session',
      ConductedBy.independent => 'independent',
    };

String responseMarkingToJson(ResponseMarking m) => switch (m) {
      ResponseMarking.independent => 'independent',
      ResponseMarking.hint => 'hint',
      ResponseMarking.noResponse => 'no_response',
    };

/// SessionStatus.values.byName() would throw on the backend's snake_case
/// "in_progress" (Dart's enum name is camelCase inProgress) — map explicitly.
SessionStatus sessionStatusFromJson(String value) => switch (value) {
      'scheduled' => SessionStatus.scheduled,
      'in_progress' => SessionStatus.inProgress,
      'completed' => SessionStatus.completed,
      'missed' => SessionStatus.missed,
      _ => throw ArgumentError('Unknown session status: $value'),
    };

String sessionStatusToJson(SessionStatus s) => switch (s) {
      SessionStatus.scheduled => 'scheduled',
      SessionStatus.inProgress => 'in_progress',
      SessionStatus.completed => 'completed',
      SessionStatus.missed => 'missed',
    };

ResponseMarking responseMarkingFromJson(String value) => switch (value) {
      'independent' => ResponseMarking.independent,
      'hint' => ResponseMarking.hint,
      'no_response' => ResponseMarking.noResponse,
      _ => throw ArgumentError('Unknown response marking: $value'),
    };

class CareSession {
  final String id;
  final SessionType type;
  final ConductedBy conductedBy;
  final String? ashaId;
  final DateTime scheduledTime;
  final SessionStatus status;
  final List<String> patientIds;

  const CareSession({
    required this.id,
    required this.type,
    required this.conductedBy,
    required this.scheduledTime,
    required this.status,
    required this.patientIds,
    this.ashaId,
  });

  bool get isGroup => type == SessionType.group;

  CareSession copyWith({SessionStatus? status}) => CareSession(
        id: id,
        type: type,
        conductedBy: conductedBy,
        ashaId: ashaId,
        scheduledTime: scheduledTime,
        status: status ?? this.status,
        patientIds: patientIds,
      );

  factory CareSession.fromJson(Map<String, dynamic> json) => CareSession(
        id: json['id'] as String,
        type: SessionType.values.byName(json['type'] as String),
        conductedBy: (json['conducted_by'] as String) == 'asha_session'
            ? ConductedBy.ashaSession
            : ConductedBy.independent,
        ashaId: json['asha_id'] as String?,
        scheduledTime: DateTime.parse(json['scheduled_time'] as String),
        status: sessionStatusFromJson(json['status'] as String),
        patientIds: List<String>.from(json['patient_ids'] as List),
      );

  Map<String, dynamic> toLocalJson() => {
        'id': id,
        'type': sessionTypeToJson(type),
        'conducted_by': conductedByToJson(conductedBy),
        'asha_id': ashaId,
        'scheduled_time': scheduledTime.toIso8601String(),
        'status': sessionStatusToJson(status),
        'patient_ids': patientIds,
      };

  /// No local-only fields yet, so this is just an alias — kept distinct from
  /// fromJson() so callers name their intent, matching toLocalJson() above.
  factory CareSession.fromLocalJson(Map<String, dynamic> json) => CareSession.fromJson(json);
}

class ResponseRecord {
  final String sessionId;
  final String patientId;
  final int roundNumber;
  final ResponseMarking marking;
  final String gameModule;
  final DateTime timestamp;

  const ResponseRecord({
    required this.sessionId,
    required this.patientId,
    required this.roundNumber,
    required this.marking,
    required this.gameModule,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'patient_id': patientId,
        'round_number': roundNumber,
        'marking': responseMarkingToJson(marking),
        'game_module': gameModule,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ResponseRecord.fromJson(Map<String, dynamic> json) => ResponseRecord(
        sessionId: json['session_id'] as String,
        patientId: json['patient_id'] as String,
        roundNumber: json['round_number'] as int,
        marking: responseMarkingFromJson(json['marking'] as String),
        gameModule: json['game_module'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
