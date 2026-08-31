import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smriti/auth/auth_gate.dart';
import 'package:smriti/core/locale_controller.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/debug/companion_debug_screen.dart';
import 'package:smriti/l10n_gen/app_localizations.dart';
import 'package:smriti/modules/asha/asha_home.dart';
import 'package:smriti/modules/asha/data/asha_repository.dart';
import 'package:smriti/modules/caregiver/caregiver_home.dart';
import 'package:smriti/modules/caregiver/data/caregiver_repository.dart';
import 'package:smriti/modules/patient/patient_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load persisted state before the first frame so screens can read repositories
  // synchronously — see LocalStore for why this is shared_preferences today.
  await Future.wait([AshaRepository.instance.load(), CaregiverRepository.instance.load()]);
  runApp(const SmritiApp());
}

class SmritiApp extends StatelessWidget {
  const SmritiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app when AppLanguageSelector (or anything else) calls
    // AppLocaleController.instance.setLocale — see core/locale_controller.dart.
    return ValueListenableBuilder<Locale?>(
      valueListenable: AppLocaleController.instance,
      builder: (context, locale, _) {
        return MaterialApp(
          // Localization infra only for now (see lib/l10n/README.md) — no screen has
          // been migrated to read strings from AppLocalizations yet. onGenerateTitle
          // is the one place already wired end-to-end, proving the pipeline works:
          // the OS-level app title switches script with the locale below.
          onGenerateTitle: (context) => AppLocalizations.of(context)?.appTitle ?? 'Smriti',
          locale: locale,
          // Already includes the Global Material/Widgets/Cupertino delegates.
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocaleController.supported,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const EntryScreen(),
          routes: {
            '/debug/companion': (context) => const CompanionDebugScreen(),
            '/debug/roles': (context) => const DevRolePickerScreen(),
          },
        );
      },
    );
  }
}

/// The real app entry point. ASHA/Caregiver go through [AuthGate]'s
/// passwordless email sign-in (see lib/auth/) — the Patient module keeps its
/// existing no-login, photo-tile flow and is reached directly, per the
/// architecture.
class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Smriti', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  'SIH26003',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuthGate()),
                    ),
                    icon: const Icon(Icons.groups_rounded),
                    label: const Text('ASHA worker / Caregiver'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PatientHome()),
                    ),
                    icon: const Icon(Icons.self_improvement_rounded),
                    label: const Text('Patient'),
                  ),
                ),
                // Only ever reachable in a debug build (flutter run) — never shown to
                // a real user in a release build, per kDebugMode. Skips straight into
                // any module for internal testing, bypassing sign-in and the
                // companion/game flows so teammates can jump around quickly.
                if (kDebugMode) ...[
                  const SizedBox(height: 32),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/debug/roles'),
                    icon: const Icon(Icons.bug_report_rounded, size: 18),
                    label: const Text('Dev: skip sign-in'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dev-only shortcut into any module, bypassing sign-in — see [EntryScreen]'s
/// kDebugMode-gated link above. Never reachable in a release build.
class DevRolePickerScreen extends StatelessWidget {
  const DevRolePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev role picker')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Internal testing only — skips sign-in entirely.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AshaHome()),
                    ),
                    icon: const Icon(Icons.groups_rounded),
                    label: const Text('ASHA worker'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CaregiverHome()),
                    ),
                    icon: const Icon(Icons.favorite_rounded),
                    label: const Text('Caregiver'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PatientHome()),
                    ),
                    icon: const Icon(Icons.self_improvement_rounded),
                    label: const Text('Patient'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/debug/companion'),
                    icon: const Icon(Icons.bug_report_rounded),
                    label: const Text('Debug Companion Widget'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
