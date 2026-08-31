/// A trend flag raised against a patient's *own* baseline.
///
/// Positioning doc, never-say table: this is always "sustained deviation from her own
/// baseline, routed to ASHA", never "detects/diagnoses dementia". Every message
/// constructed for one of these must stay on the "say instead" side of that table.
class AlertItem {
  final String id;
  final String patientId;
  final String patientName;
  final String message;
  final DateTime timestamp;
  final bool reviewed;

  const AlertItem({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.message,
    required this.timestamp,
    this.reviewed = false,
  });

  AlertItem copyWith({bool? reviewed}) => AlertItem(
        id: id,
        patientId: patientId,
        patientName: patientName,
        message: message,
        timestamp: timestamp,
        reviewed: reviewed ?? this.reviewed,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'patient_name': patientName,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'reviewed': reviewed,
      };

  factory AlertItem.fromJson(Map<String, dynamic> json) => AlertItem(
        id: json['id'] as String,
        // Tolerate rows written before patient_id was tracked.
        patientId: json['patient_id'] as String? ?? 'unknown',
        patientName: json['patient_name'] as String,
        message: json['message'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        reviewed: json['reviewed'] as bool? ?? false,
      );
}
