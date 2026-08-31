import 'package:flutter/material.dart';
import 'package:smriti/core/local_db/alert_store.dart';
import 'package:smriti/core/repository_listener.dart';
import 'package:smriti/modules/asha/data/asha_repository.dart';
import 'package:smriti/modules/asha/screens/new_patient_screen.dart';
import 'package:smriti/modules/asha/screens/patient_detail_screen.dart';
import 'package:smriti/modules/asha/widgets/patient_tile.dart';
import 'package:smriti/widgets/sign_out_button.dart';

/// Panel 2 of 3. Roster assigned to this ASHA, surfacing trend flags and missed sessions
/// at a glance — never phrased as diagnosis, only deviation from her own baseline.
class MyPatientsScreen extends StatefulWidget {
  const MyPatientsScreen({super.key});

  @override
  State<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

class _MyPatientsScreenState extends State<MyPatientsScreen> with RepositoryListener {
  final _repo = AshaRepository.instance;

  @override
  void initState() {
    super.initState();
    // A session completed on the Sessions tab can flag someone on this roster.
    listenTo([_repo.onChange, AlertStore.instance.onChange]);
  }

  @override
  Widget build(BuildContext context) {
    // Anyone needing attention rises to the top: flagged first, then missed sessions,
    // then everyone else. An ASHA with thirty patients should not have to hunt.
    final patients = [..._repo.patients]..sort((a, b) {
        int rank(p) => p.trendFlag != null ? 0 : (_repo.missedSessionCountFor(p.id) > 0 ? 1 : 2);
        final byRank = rank(a).compareTo(rank(b));
        return byRank != 0 ? byRank : a.name.compareTo(b.name);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('My Patients'), actions: const [SignOutButton()]),
      floatingActionButton: FloatingActionButton.extended(
        // Unique tag required: this panel and Today's Sessions are both mounted inside
        // AshaHome's IndexedStack, and two default-tagged FABs crash the route animation.
        heroTag: 'fab-onboard-patient',
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const NewPatientScreen()),
          );
          setState(() {});
          if (added == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient onboarded')));
          }
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Onboard patient'),
      ),
      body: patients.isEmpty
          ? const Center(child: Text('No patients on your roster yet.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: patients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final patient = patients[index];
                return PatientTile(
                  patient: patient,
                  missedSessionCount: _repo.missedSessionCountFor(patient.id),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PatientDetailScreen(patientId: patient.id)),
                    );
                    setState(() {});
                  },
                );
              },
            ),
    );
  }
}
