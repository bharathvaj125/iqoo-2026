enum ReminderType { medicine, hydration, activity, appointment }

enum AckStatus { acknowledged, missed }

extension ReminderTypeLabel on ReminderType {
  String get label => switch (this) {
        ReminderType.medicine => 'Medicine',
        ReminderType.hydration => 'Hydration',
        ReminderType.activity => 'Daily activity',
        ReminderType.appointment => 'Appointment',
      };
}

class Reminder {
  final String id;
  final String patientId;

  /// A caregiver_id, or an ASHA acting as fallback caregiver-of-record.
  final String createdBy;
  final ReminderType type;
  final String schedule;

  /// Null falls back to TTS; recorded family-voice clips are the headline feature.
  final String? voiceClipUrl;
  final String textLabel;

  const Reminder({
    required this.id,
    required this.patientId,
    required this.createdBy,
    required this.type,
    required this.schedule,
    required this.textLabel,
    this.voiceClipUrl,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        createdBy: json['created_by'] as String,
        type: ReminderType.values.byName(json['type'] as String),
        schedule: json['schedule'] as String,
        voiceClipUrl: json['voice_clip_url'] as String?,
        textLabel: json['text_label'] as String,
      );

  Map<String, dynamic> toJson() => {
        'patient_id': patientId,
        'created_by': createdBy,
        'type': type.name,
        'schedule': schedule,
        'voice_clip_url': voiceClipUrl,
        'text_label': textLabel,
      };
}

class ReminderAck {
  final String reminderId;
  final String patientId;
  final DateTime timestamp;
  final AckStatus status;

  const ReminderAck({
    required this.reminderId,
    required this.patientId,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'reminder_id': reminderId,
        'patient_id': patientId,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
      };

  factory ReminderAck.fromJson(Map<String, dynamic> json) => ReminderAck(
        reminderId: json['reminder_id'] as String,
        patientId: json['patient_id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        status: AckStatus.values.byName(json['status'] as String),
      );
}
