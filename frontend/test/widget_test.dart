import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smriti/core/local_db/alert_store.dart';
import 'package:smriti/core/local_db/local_store.dart';
import 'package:smriti/main.dart';
import 'package:smriti/modules/asha/data/asha_repository.dart';
import 'package:smriti/modules/caregiver/data/caregiver_repository.dart';

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

  testWidgets('role picker shows ASHA worker and Caregiver entry points', (tester) async {
    await tester.pumpWidget(const SmritiApp());

    expect(find.text('Smriti'), findsOneWidget);
    expect(find.text('ASHA worker'), findsOneWidget);
    expect(find.text('Caregiver'), findsOneWidget);
  });

  testWidgets("tapping ASHA worker opens Today's Sessions", (tester) async {
    await tester.pumpWidget(const SmritiApp());

    await tester.tap(find.text('ASHA worker'));
    await tester.pumpAndSettle();

    expect(find.text("Today's Sessions"), findsOneWidget);
    expect(find.text('New session'), findsOneWidget);
  });

  testWidgets('ASHA can reach the patient roster, which flags who has no baseline', (tester) async {
    await tester.pumpWidget(const SmritiApp());
    await tester.tap(find.text('ASHA worker'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Patients'));
    await tester.pumpAndSettle();

    expect(find.text('My Patients'), findsOneWidget);
    // Wanpen Marak is seeded without a baseline so the onboarding path stays visible.
    expect(find.text('No baseline'), findsOneWidget);
    expect(find.text('Onboard patient'), findsOneWidget);
  });

  testWidgets('tapping Caregiver opens the Dashboard', (tester) async {
    await tester.pumpWidget(const SmritiApp());

    await tester.tap(find.text('Caregiver'));
    await tester.pumpAndSettle();

    // "Dashboard" appears twice: the AppBar title and the bottom-nav label.
    expect(find.text('Dashboard'), findsWidgets);
  });

  testWidgets('caregiver dashboard reports real attendance, not a fixed number', (tester) async {
    await tester.pumpWidget(const SmritiApp());
    await tester.tap(find.text('Caregiver'));
    await tester.pumpAndSettle();

    // Nothing has been completed yet, so attendance has no data to show.
    expect(find.text('None scheduled'), findsOneWidget);

    // The old build hardcoded 4 of 5 sessions regardless of what had happened.
    expect(find.textContaining('4/5'), findsNothing);
  });
}
