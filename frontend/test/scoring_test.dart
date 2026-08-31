import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smriti/core/local_db/alert_store.dart';
import 'package:smriti/core/local_db/local_store.dart';
import 'package:smriti/core/models/reminder.dart';
import 'package:smriti/core/models/session.dart';
import 'package:smriti/modules/asha/data/asha_repository.dart';
import 'package:smriti/modules/caregiver/data/caregiver_repository.dart';

/// Covers the scoring and derivation rules that are easy to get quietly wrong:
/// own-baseline drift, assisted/independent separation, and the dashboard numbers that
/// used to be hardcoded.
void main() {
  late AshaRepository asha;
  late CaregiverRepository caregiver;

  setUp(() async {
    // These repositories are app-lifetime singletons, so each test has to explicitly put
    // them back to a cold-start state or it inherits the previous test's data.
    SharedPreferences.setMockInitialValues({});
    LocalStore.instance.resetForTest();
    AlertStore.instance.resetForTest();
    AshaRepository.instance.resetForTest();
    CaregiverRepository.instance.resetForTest();

    asha = AshaRepository.instance;
    caregiver = CaregiverRepository.instance;
    await asha.load();
    await caregiver.load();
  });

  Future<void> logRounds(String sessionId, String patientId, List<ResponseMarking> markings) async {
    for (var i = 0; i < markings.length; i++) {
      await asha.recordResponse(
        ResponseRecord(
          sessionId: sessionId,
          patientId: patientId,
          roundNumber: i + 1,
          marking: markings[i],
          gameModule: 'memory_matching',
          timestamp: DateTime.now().add(Duration(seconds: i)),
        ),
      );
    }
  }

  test('a patient performing at her baseline is not flagged', () async {
    // p1's onboarding baseline is 25% hint dependence; 2 of 6 rounds needing help is 33%,
    // inside the drift threshold.
    await logRounds('s1', 'p1', [
      ResponseMarking.independent,
      ResponseMarking.independent,
      ResponseMarking.hint,
      ResponseMarking.independent,
      ResponseMarking.hint,
      ResponseMarking.independent,
    ]);
    await asha.completeSession('s1');

    expect(asha.patientById('p1').trendFlag, isNull);
  });

  test('sustained drift above her own baseline raises a flag that reaches the caregiver', () async {
    await logRounds('s1', 'p1', [
      ResponseMarking.hint,
      ResponseMarking.noResponse,
      ResponseMarking.hint,
      ResponseMarking.hint,
      ResponseMarking.noResponse,
      ResponseMarking.independent,
    ]);
    await asha.completeSession('s1');

    final flag = asha.patientById('p1').trendFlag;
    expect(flag, isNotNull);
    // Positioning doc: trends, never diagnosis.
    expect(flag!.toLowerCase(), isNot(contains('dementia')));
    expect(flag, contains('baseline'));

    // The whole point of the shared alert store — a flag raised on the ASHA side has to
    // show up for the caregiver.
    expect(caregiver.alerts.any((a) => a.patientId == 'p1' && !a.reviewed), isTrue);
  });

  test('a patient with no baseline is never scored against nothing', () async {
    // p3 is seeded deliberately without a baseline.
    expect(asha.patientById('p3').hasBaseline, isFalse);

    await logRounds('s2', 'p3', List.filled(6, ResponseMarking.noResponse));
    await asha.completeSession('s2');

    expect(asha.patientById('p3').trendFlag, isNull);
  });

  test('independent home play never triggers a flag on its own', () async {
    // Six terrible rounds — but played alone at home, where nobody was there to offer a
    // hint. Pooling these with assisted rounds would manufacture a flag out of a
    // difference in circumstance rather than a change in her.
    final solo = await asha.recordIndependentSession(patientId: 'p2', playedAt: DateTime.now());
    await logRounds(solo.id, 'p2', List.filled(6, ResponseMarking.noResponse));
    await asha.completeSession(solo.id);

    expect(asha.patientById('p2').trendFlag, isNull);
  });

  test('assisted rounds still flag normally for a patient who also plays alone', () async {
    final solo = await asha.recordIndependentSession(patientId: 'p2', playedAt: DateTime.now());
    await logRounds(solo.id, 'p2', List.filled(6, ResponseMarking.noResponse));

    // p2's baseline is 15% hint dependence; six assisted rounds all needing help is 100%.
    await logRounds('s1', 'p2', List.filled(6, ResponseMarking.hint));
    await asha.completeSession('s1');

    expect(asha.patientById('p2').trendFlag, isNotNull);
  });

  test('onboarding a patient queues sync and starts with no baseline', () async {
    final before = asha.outbox.length;
    final patient = await asha.addPatient(name: 'Test Elder', language: 'Khasi', age: 70);

    expect(patient.hasBaseline, isFalse);
    expect(asha.outbox.length, greaterThan(before));
    expect(asha.outbox.last.description, contains('Test Elder'));
  });

  test('captured baseline is stored and makes the patient scoreable', () async {
    await asha.captureBaseline(patientId: 'p3', reactionTimeMs: 2200, errorRate: 14, hintDependence: 20);
    final p3 = asha.patientById('p3');

    expect(p3.hasBaseline, isTrue);
    expect(p3.baselineHintDependence, 20);
  });

  test('missed sessions are derived from session records, not a stored counter', () async {
    expect(asha.missedSessionCountFor('p3'), 0);
    await asha.markSessionMissed('s2'); // s2 is p3's outreach visit
    expect(asha.missedSessionCountFor('p3'), 1);
  });

  test('digest attendance reflects real sessions rather than fixed numbers', () async {
    final before = caregiver.weeklyDigest;
    expect(before.sessionsAttended, 0);

    await asha.completeSession('s1'); // s1 includes p1, the caregiver's patient
    final after = caregiver.weeklyDigest;

    expect(after.sessionsAttended, 1);
    expect(after.highlights.first, contains('1 of 1'));
  });

  test('adherence is reported per reminder type, worst first', () {
    final byType = caregiver.adherenceByType();

    expect(byType, isNotEmpty);
    for (var i = 1; i < byType.length; i++) {
      expect(byType[i - 1].rate, lessThanOrEqualTo(byType[i].rate));
    }
  });

  test('a brand new reminder reports no data rather than perfect adherence', () async {
    await caregiver.addReminder(
      const Reminder(
        id: 'r-new',
        patientId: 'p1',
        createdBy: 'caregiver-demo-1',
        type: ReminderType.hydration,
        schedule: 'Daily 09:00',
        textLabel: 'Morning glass of water',
      ),
    );

    final fresh = caregiver.adherenceFor('r-new');
    expect(fresh.hasData, isFalse);
    expect(fresh.total, 0);
  });

  test('a recorded voice clip becomes reusable on later reminders', () async {
    await caregiver.addReminder(
      const Reminder(
        id: 'r-voice',
        patientId: 'p1',
        createdBy: 'caregiver-demo-1',
        type: ReminderType.medicine,
        schedule: 'Daily 07:00',
        textLabel: 'Morning tablet',
        voiceClipUrl: 'file:///clip-a.m4a',
      ),
    );

    expect(caregiver.voiceClips, contains('file:///clip-a.m4a'));
  });
}
