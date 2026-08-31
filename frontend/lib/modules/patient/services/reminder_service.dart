import 'dart:async';
import 'package:flutter/material.dart' show TimeOfDay, ChangeNotifier;

import '../models/patient_models.dart';
import 'local_store.dart';

/// App-wide reminder clock. Any screen (game screens especially) can
/// listen to [activeReminder] to know when to pause and switch the
/// companion into "task mode", per the spec's interrupt/resume flow.
///
/// For the hackathon prototype this checks real wall-clock time against
/// each reminder's `timeOfDay` on a short timer, AND exposes
/// [fireForDemo] so the flow can be demonstrated on demand without
/// waiting for the actual clock to reach a reminder's time.
class ReminderService extends ChangeNotifier {
  ReminderService._internal() {
    _load();
    _clock = Timer.periodic(const Duration(seconds: 20), (_) => _checkClock());
  }
  static final ReminderService instance = ReminderService._internal();

  final List<ReminderItem> reminders = [
    ReminderItem(
      id: 'rem_morning_med',
      title: 'Take your morning medicine',
      category: 'medicine',
      timeOfDay: '08:00',
    ),
    ReminderItem(
      id: 'rem_water',
      title: 'Drink a glass of water',
      category: 'hydration',
      timeOfDay: '10:30',
    ),
    ReminderItem(
      id: 'rem_afternoon_med',
      title: 'Take your afternoon medicine',
      category: 'medicine',
      timeOfDay: '14:00',
    ),
    ReminderItem(
      id: 'rem_appointment',
      title: 'PHC check-up appointment',
      category: 'appointment',
      timeOfDay: '16:00',
    ),
  ];

  /// The reminder currently interrupting the patient, if any. Game
  /// screens should watch this via [addListener] and pause/snapshot the
  /// instant it becomes non-null.
  ReminderItem? activeReminder;

  Timer? _clock;
  final Set<String> _firedToday = {};

  Future<void> _load() async {
    // In a full build this would hydrate acknowledgement state from
    // LocalStore; kept minimal here since acks reset daily by design.
  }

  void _checkClock() {
    final now = TimeOfDay.now();
    for (final r in reminders) {
      if (_firedToday.contains(r.id)) continue;
      final parts = r.timeOfDay.split(':');
      final hh = int.parse(parts[0]);
      final mm = int.parse(parts[1]);
      if (now.hour == hh && now.minute >= mm && now.minute < mm + 1) {
        fire(r);
      }
    }
  }

  /// Fires [reminder] immediately — used both by the real clock check and
  /// by a demo "Trigger now" button so the interrupt/resume flow can be
  /// shown without waiting for wall-clock time.
  void fire(ReminderItem reminder) {
    if (activeReminder != null) return; // one interruption at a time
    _firedToday.add(reminder.id);
    reminder.lastFiredAt = DateTime.now();
    reminder.acknowledgedToday = false;
    activeReminder = reminder;
    notifyListeners();
  }

  void fireForDemo(String reminderId) {
    final r = reminders.firstWhere((r) => r.id == reminderId);
    _firedToday.remove(reminderId); // allow re-demoing the same reminder
    fire(r);
  }

  /// Called when the patient taps the big "I did it" button.
  Future<void> acknowledge(String patientId) async {
    final r = activeReminder;
    if (r == null) return;
    r.acknowledgedToday = true;
    r.lastAcknowledgedAt = DateTime.now();
    await LocalStore().logReminderAck(
      ReminderAck(
        reminderId: r.id,
        patientId: patientId,
        acknowledgedAt: r.lastAcknowledgedAt!,
      ),
    );
    activeReminder = null;
    notifyListeners();
  }

  void resetDailyFlagsForDemo() {
    _firedToday.clear();
    for (final r in reminders) {
      r.acknowledgedToday = false;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }
}
