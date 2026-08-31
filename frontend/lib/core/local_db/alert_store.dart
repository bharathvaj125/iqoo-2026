import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:smriti/core/local_db/local_store.dart';
import 'package:smriti/core/models/alert.dart';

/// Trend flags are raised on the ASHA side (after a session is scored against the
/// patient's own baseline) and consumed on the caregiver side. In the real system both
/// dashboards read the same rows out of the on-device DB, so they share one store here
/// rather than each keeping a private copy — otherwise a flag raised in a session would
/// never reach the caregiver's Alerts tab, which is the whole point of the feature.
class AlertStore {
  AlertStore._();

  static final AlertStore instance = AlertStore._();

  static const _key = 'care_alerts_v1';

  final List<AlertItem> _alerts = [];
  bool _loaded = false;

  final _changes = StreamController<void>.broadcast();
  Stream<void> get onChange => _changes.stream;

  List<AlertItem> get all => List.unmodifiable(_alerts);

  List<AlertItem> get open => _alerts.where((a) => !a.reviewed).toList();

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final rows = await LocalStore.instance.readList(_key);
    _alerts.addAll(rows.map(AlertItem.fromJson));
  }

  /// Replaces any existing open flag for the same patient rather than stacking
  /// duplicates every session — a caregiver should see "this is still true", not a
  /// growing pile of identical rows.
  Future<void> raise({
    required String patientId,
    required String patientName,
    required String message,
  }) async {
    _alerts.removeWhere((a) => a.patientId == patientId && !a.reviewed);
    _alerts.add(
      AlertItem(
        id: 'alert-${DateTime.now().microsecondsSinceEpoch}',
        patientId: patientId,
        patientName: patientName,
        message: message,
        timestamp: DateTime.now(),
      ),
    );
    await _persist();
    _changes.add(null);
  }

  /// Called when a patient's trend recovers — an open flag that no longer holds should
  /// disappear rather than sit there implying an ongoing problem.
  Future<void> clearOpenFor(String patientId) async {
    final before = _alerts.length;
    _alerts.removeWhere((a) => a.patientId == patientId && !a.reviewed);
    if (_alerts.length == before) return;
    await _persist();
    _changes.add(null);
  }

  Future<void> markReviewed(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index == -1) return;
    _alerts[index] = _alerts[index].copyWith(reviewed: true);
    await _persist();
    _changes.add(null);
  }

  Future<void> seedIfEmpty(List<AlertItem> seed) async {
    if (_alerts.isNotEmpty) return;
    _alerts.addAll(seed);
    await _persist();
  }

  Future<void> _persist() => LocalStore.instance.writeList(_key, _alerts.map((a) => a.toJson()).toList());

  @visibleForTesting
  void resetForTest() {
    _alerts.clear();
    _loaded = false;
  }
}
