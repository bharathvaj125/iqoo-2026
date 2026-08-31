/// The caregiver spec is explicit that not every patient has a family caregiver:
/// where none exists, the ASHA is the caregiver-of-record. Permissions and dashboard
/// framing differ slightly between the two, so the distinction is a first-class field
/// rather than something inferred later.
enum CaregiverKind { family, ashaFallback }

extension CaregiverKindLabel on CaregiverKind {
  String get label => switch (this) {
        CaregiverKind.family => 'Family caregiver',
        CaregiverKind.ashaFallback => 'ASHA (caregiver-of-record)',
      };

  /// The ASHA sees a patient roster and already has her own module; a distant family
  /// member sees one elder. Framing the dashboard differently keeps both honest.
  String get dashboardContext => switch (this) {
        CaregiverKind.family => 'Checking in on your family member',
        CaregiverKind.ashaFallback => 'No family caregiver registered — you are caregiver-of-record',
      };
}

class CaregiverProfile {
  final String id;
  final String name;
  final CaregiverKind kind;
  final String? photoUrl;

  /// Which elder this dashboard is scoped to.
  final String patientId;

  const CaregiverProfile({
    required this.id,
    required this.name,
    required this.kind,
    required this.patientId,
    this.photoUrl,
  });

  bool get isAshaFallback => kind == CaregiverKind.ashaFallback;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'patient_id': patientId,
        'photo_url': photoUrl,
      };

  factory CaregiverProfile.fromJson(Map<String, dynamic> json) => CaregiverProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: CaregiverKind.values.byName(json['kind'] as String),
        patientId: json['patient_id'] as String,
        photoUrl: json['photo_url'] as String?,
      );
}
