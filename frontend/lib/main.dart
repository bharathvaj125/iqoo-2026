import 'package:flutter/material.dart';
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
          },
        );
      },
    );
  }
}

/// The app's real entry point: three direct-entry tiles, no credentials, no
/// intermediate screen. This build has no authentication anywhere — tapping a
/// tile is pure navigation into that role's view.
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
                  'Memory care, made simple',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 40),
                _RoleTile(
                  label: 'ASHA Worker',
                  icon: Icons.groups_rounded,
                  color: AppTheme.primary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AshaHome()),
                  ),
                ),
                const SizedBox(height: 16),
                _RoleTile(
                  label: 'Patient',
                  icon: Icons.self_improvement_rounded,
                  color: AppTheme.accent,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PatientHome()),
                  ),
                ),
                const SizedBox(height: 16),
                _RoleTile(
                  label: 'Caregiver',
                  icon: Icons.favorite_rounded,
                  color: AppTheme.primary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CaregiverHome()),
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

class _RoleTile extends StatelessWidget {
  const _RoleTile({required this.label, required this.icon, required this.color, required this.onTap});

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 28),
        label: Text(label),
      ),
    );
  }
}
