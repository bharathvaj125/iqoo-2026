import 'package:flutter/material.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/modules/asha/asha_home.dart';
import 'package:smriti/modules/asha/data/asha_repository.dart';
import 'package:smriti/modules/caregiver/caregiver_home.dart';
import 'package:smriti/modules/caregiver/data/caregiver_repository.dart';
import 'package:smriti/modules/patient/patient_home.dart';
import 'package:smriti/debug/companion_debug_screen.dart';

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
    return MaterialApp(
      title: 'Smriti',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const RoleSelectScreen(),
      routes: {
        '/debug/companion': (context) => const CompanionDebugScreen(),
      },
    );
  }
}

/// Dev-only entry point for this branch. Each role authenticates for real
/// (JWT for ASHA/caregiver, photo-tile for the patient) once that's wired up;
/// this picker stands in for all three during module development.
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

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
                  'SIH26003 — dev role picker',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 40),
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
