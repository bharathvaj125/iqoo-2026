import 'package:flutter/material.dart';
import 'package:smriti/modules/caregiver/screens/alerts_screen.dart';
import 'package:smriti/modules/caregiver/screens/dashboard_screen.dart';
import 'package:smriti/modules/caregiver/screens/digest_screen.dart';
import 'package:smriti/modules/caregiver/screens/goals_screen.dart';
import 'package:smriti/modules/caregiver/screens/reminders_screen.dart';
import 'package:smriti/widgets/module_companion_header.dart';

class CaregiverHome extends StatefulWidget {
  const CaregiverHome({super.key});

  @override
  State<CaregiverHome> createState() => _CaregiverHomeState();
}

class _CaregiverHomeState extends State<CaregiverHome> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    RemindersScreen(),
    GoalsScreen(),
    AlertsScreen(),
    DigestScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ModuleCompanionHeader(label: 'Smriti — Caregiver'),
          Expanded(child: IndexedStack(index: _index, children: _screens)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.notifications_active_rounded), label: 'Reminders'),
          NavigationDestination(icon: Icon(Icons.checklist_rounded), label: 'Goals'),
          NavigationDestination(icon: Icon(Icons.flag_rounded), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.summarize_rounded), label: 'Digest'),
        ],
      ),
    );
  }
}
