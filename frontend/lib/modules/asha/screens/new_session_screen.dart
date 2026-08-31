import 'package:flutter/material.dart';
import 'package:smriti/core/models/session.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/modules/asha/data/asha_repository.dart';

/// Deliberately defaults to group + multi-select. Solo/outreach is one tap away,
/// not the starting state — see "what NOT to build here" in the ASHA spec.
class NewSessionScreen extends StatefulWidget {
  const NewSessionScreen({super.key});

  @override
  State<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends State<NewSessionScreen> {
  final _repo = AshaRepository.instance;
  SessionType _type = SessionType.group;
  final Set<String> _selectedPatientIds = {};
  TimeOfDay _time = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    final patients = _repo.patients;

    return Scaffold(
      appBar: AppBar(title: const Text('New session')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Session type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<SessionType>(
            segments: const [
              ButtonSegment(value: SessionType.group, label: Text('Group'), icon: Icon(Icons.groups_rounded)),
              ButtonSegment(value: SessionType.solo, label: Text('Solo'), icon: Icon(Icons.person_rounded)),
              ButtonSegment(
                value: SessionType.outreach,
                label: Text('Outreach'),
                icon: Icon(Icons.directions_walk_rounded),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (selection) => setState(() {
              _type = selection.first;
              if (_type != SessionType.group && _selectedPatientIds.length > 1) {
                _selectedPatientIds.retainWhere((id) => id == _selectedPatientIds.first);
              }
            }),
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showTimePicker(context: context, initialTime: _time);
                if (picked != null) setState(() => _time = picked);
              },
              child: Text(_time.format(context), style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _type == SessionType.group ? 'Select patients' : 'Select patient',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...patients.map((p) {
            final selected = _selectedPatientIds.contains(p.id);
            return CheckboxListTile(
              value: selected,
              title: Text(p.name),
              subtitle: Text(p.language),
              onChanged: (checked) => setState(() {
                if (_type != SessionType.group) {
                  _selectedPatientIds.clear();
                }
                if (checked == true) {
                  _selectedPatientIds.add(p.id);
                } else {
                  _selectedPatientIds.remove(p.id);
                }
              }),
            );
          }),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            onPressed: _selectedPatientIds.isEmpty
                ? null
                : () async {
                    final now = DateTime.now();
                    await _repo.createSession(
                      type: _type,
                      patientIds: _selectedPatientIds.toList(),
                      scheduledTime: DateTime(now.year, now.month, now.day, _time.hour, _time.minute),
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).pop(true);
                  },
            child: const Text('Schedule session'),
          ),
        ],
      ),
    );
  }
}
