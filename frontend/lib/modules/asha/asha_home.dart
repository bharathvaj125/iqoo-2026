import 'package:flutter/material.dart';
import 'package:smriti/modules/asha/screens/my_patients_screen.dart';
import 'package:smriti/modules/asha/screens/sync_screen.dart';
import 'package:smriti/modules/asha/screens/today_sessions_screen.dart';
import 'package:smriti/widgets/module_companion_header.dart';

/// The three established panels, per the ASHA module spec: Today's Sessions / My Patients / Sync.
class AshaHome extends StatefulWidget {
  const AshaHome({super.key});

  @override
  State<AshaHome> createState() => _AshaHomeState();
}

class _AshaHomeState extends State<AshaHome> {
  int _index = 0;

  static const _screens = [TodaySessionsScreen(), MyPatientsScreen(), SyncScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ModuleCompanionHeader(label: 'Smriti — ASHA'),
          Expanded(child: IndexedStack(index: _index, children: _screens)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_rounded), label: 'Sessions'),
          NavigationDestination(icon: Icon(Icons.people_alt_rounded), label: 'Patients'),
          NavigationDestination(icon: Icon(Icons.sync_rounded), label: 'Sync'),
        ],
      ),
    );
  }
}
