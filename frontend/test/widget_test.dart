import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smriti/core/local_db/alert_store.dart';
import 'package:smriti/core/local_db/local_store.dart';
import 'package:smriti/main.dart';
import 'package:smriti/modules/asha/data/asha_repository.dart';
import 'package:smriti/modules/caregiver/data/caregiver_repository.dart';

/// `pumpAndSettle()` waits until nothing is animating — which never happens once
/// a screen is showing `ModuleCompanionHeader`'s CompanionWidget, whose idle
/// float/blink/glow/mist animations repeat forever by design. Any test that
/// lands on AshaHome/CaregiverHome (both now show that header) needs this bounded
/// pump instead: enough frames for the ~280ms fadeSlideRoute transition and any
/// state updates to finish, without waiting for an animation that's supposed to
/// keep going.
Future<void> pumpBriefly(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  setUp(() async {
    // Load the repositories the way main() does, so these screens render against the
    // same seeded data a real cold start would give them.
    SharedPreferences.setMockInitialValues({});
    LocalStore.instance.resetForTest();
    AlertStore.instance.resetForTest();
    AshaRepository.instance.resetForTest();
    CaregiverRepository.instance.resetForTest();
    await AshaRepository.instance.load();
    await CaregiverRepository.instance.load();
  });

  testWidgets('entry screen offers direct-entry tiles for all three roles, no sign-in', (tester) async {
    await tester.pumpWidget(const SmritiApp());

    expect(find.text('Smriti'), findsOneWidget);
    expect(find.text('ASHA Worker'), findsOneWidget);
    expect(find.text('Patient'), findsOneWidget);
    expect(find.text('Caregiver'), findsOneWidget);
  });

  testWidgets("tapping ASHA Worker opens Today's Sessions directly, no sign-in", (tester) async {
    await tester.pumpWidget(const SmritiApp());

    await tester.tap(find.text('ASHA Worker'));
    await pumpBriefly(tester);

    expect(find.text("Today's Sessions"), findsOneWidget);
    expect(find.text('New session'), findsOneWidget);
  });

  testWidgets('ASHA can reach the patient roster, which flags who has no baseline', (tester) async {
    await tester.pumpWidget(const SmritiApp());
    await tester.tap(find.text('ASHA Worker'));
    await pumpBriefly(tester);

    await tester.tap(find.text('Patients'));
    await pumpBriefly(tester);

    expect(find.text('My Patients'), findsOneWidget);
    // Wanpen Marak is seeded without a baseline so the onboarding path stays visible.
    expect(find.text('No baseline'), findsOneWidget);
    expect(find.text('Onboard patient'), findsOneWidget);
  });

  testWidgets('tapping Caregiver opens the Dashboard directly, no sign-in', (tester) async {
    await tester.pumpWidget(const SmritiApp());

    await tester.tap(find.text('Caregiver'));
    await pumpBriefly(tester);

    // "Dashboard" appears twice: the AppBar title and the bottom-nav label.
    expect(find.text('Dashboard'), findsWidgets);
  });

  testWidgets('caregiver dashboard reports real attendance, not a fixed number', (tester) async {
    await tester.pumpWidget(const SmritiApp());
    await tester.tap(find.text('Caregiver'));
    await pumpBriefly(tester);

    // Nothing has been completed yet, so attendance has no data to show.
    expect(find.text('None scheduled'), findsOneWidget);

    // The old build hardcoded 4 of 5 sessions regardless of what had happened.
    expect(find.textContaining('4/5'), findsNothing);
  });
}
