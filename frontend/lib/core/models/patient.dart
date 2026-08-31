class Patient {
  final String id;
  final String name;
  final String? photoUrl;
  final int? age;
  final String language;
  final String assignedAshaId;
  final String? primaryCaregiverId;

  /// Own-baseline scoring: every elder is her own control, never compared to population norms.
  final int? baselineReactionTimeMs;
  final int? baselineErrorRate;
  final int? baselineHintDependence;

  /// UI-only convenience fields for the roster/trend views — not part of the API contract.
  final int missedSessionCount;
  final String? trendFlag;

  const Patient({
    required this.id,
    required this.name,
    required this.language,
    required this.assignedAshaId,
    this.photoUrl,
    this.age,
    this.primaryCaregiverId,
    this.baselineReactionTimeMs,
    this.baselineErrorRate,
    this.baselineHintDependence,
    this.missedSessionCount = 0,
    this.trendFlag,
  });

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'] as String,
        name: json['name'] as String,
        photoUrl: json['photo_url'] as String?,
        age: json['age'] as int?,
        language: json['language'] as String,
        assignedAshaId: json['assigned_asha_id'] as String,
        primaryCaregiverId: json['primary_caregiver_id'] as String?,
        baselineReactionTimeMs: json['baseline_reaction_time_ms'] as int?,
        baselineErrorRate: json['baseline_error_rate'] as int?,
        baselineHintDependence: json['baseline_hint_dependence'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'photo_url': photoUrl,
        'age': age,
        'language': language,
        'assigned_asha_id': assignedAshaId,
        'primary_caregiver_id': primaryCaregiverId,
        'baseline_reaction_time_ms': baselineReactionTimeMs,
        'baseline_error_rate': baselineErrorRate,
        'baseline_hint_dependence': baselineHintDependence,
      };

  bool get hasBaseline => baselineReactionTimeMs != null;

  /// [trendFlag] is intentionally clear-on-omit: recomputing a patient's trend has to be
  /// able to *remove* a flag that no longer holds, which a `?? this.trendFlag` fallback
  /// would make impossible. Every other field keeps its value when omitted.
  Patient copyWith({
    int? missedSessionCount,
    String? trendFlag,
    int? baselineReactionTimeMs,
    int? baselineErrorRate,
    int? baselineHintDependence,
    String? primaryCaregiverId,
  }) =>
      Patient(
        id: id,
        name: name,
        language: language,
        assignedAshaId: assignedAshaId,
        photoUrl: photoUrl,
        age: age,
        primaryCaregiverId: primaryCaregiverId ?? this.primaryCaregiverId,
        baselineReactionTimeMs: baselineReactionTimeMs ?? this.baselineReactionTimeMs,
        baselineErrorRate: baselineErrorRate ?? this.baselineErrorRate,
        baselineHintDependence: baselineHintDependence ?? this.baselineHintDependence,
        missedSessionCount: missedSessionCount ?? this.missedSessionCount,
        trendFlag: trendFlag,
      );

  /// Full round-trip including id and UI-only fields, for local on-device persistence.
  /// Distinct from toJson()/fromJson(), which mirror the backend API contract.
  Map<String, dynamic> toLocalJson() => {...toJson(), 'id': id, 'missed_session_count': missedSessionCount, 'trend_flag': trendFlag};

  factory Patient.fromLocalJson(Map<String, dynamic> json) => Patient(
        id: json['id'] as String,
        name: json['name'] as String,
        photoUrl: json['photo_url'] as String?,
        age: json['age'] as int?,
        language: json['language'] as String,
        assignedAshaId: json['assigned_asha_id'] as String,
        primaryCaregiverId: json['primary_caregiver_id'] as String?,
        baselineReactionTimeMs: json['baseline_reaction_time_ms'] as int?,
        baselineErrorRate: json['baseline_error_rate'] as int?,
        baselineHintDependence: json['baseline_hint_dependence'] as int?,
        missedSessionCount: json['missed_session_count'] as int? ?? 0,
        trendFlag: json['trend_flag'] as String?,
      );
}
