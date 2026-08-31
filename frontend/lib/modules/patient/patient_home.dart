import 'package:flutter/material.dart';
import 'package:smriti/core/theme.dart';
import 'screens/welcome_screen.dart';

/// Entry point for the elder-facing module, mirroring AshaHome/CaregiverHome
/// as the third module's root widget.
///
/// This subtree runs on [AppTheme.elder] — larger type, taller tap targets —
/// rather than the dashboard theme the other two modules use. Wrapping in a
/// [Theme] here, instead of switching the app-level theme in main.dart, keeps
/// each module's density local to itself: navigating back to the role picker
/// or into ASHA/Caregiver doesn't require the outer theme to know when the
/// patient module is on screen.
class PatientHome extends StatelessWidget {
  const PatientHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.elder,
      child: const WelcomeScreen(),
    );
  }
}
