import 'package:flutter/material.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/modules/asha/data/asha_repository.dart';
import 'package:smriti/modules/asha/screens/baseline_capture_screen.dart';

/// Patient onboarding, run by the ASHA on her tablet. Identity first, then the baseline
/// capture that everything downstream is scored against — offered immediately, but not
/// forced, since an ASHA registering someone at a camp may not have time to run a full
/// session there and then.
class NewPatientScreen extends StatefulWidget {
  const NewPatientScreen({super.key});

  @override
  State<NewPatientScreen> createState() => _NewPatientScreenState();
}

class _NewPatientScreenState extends State<NewPatientScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  /// The three languages the pitch commits to having fully built. Free text stays
  /// available because the architecture takes a new language as a content pack.
  static const _languages = ['Nagamese', 'Meitei', 'Garo', 'Khasi', 'Mizo', 'Bodo', 'Assamese'];
  String _language = _languages.first;

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _save({required bool captureBaselineNext}) async {
    setState(() => _saving = true);
    final patient = await AshaRepository.instance.addPatient(
      name: _nameController.text.trim(),
      language: _language,
      age: int.tryParse(_ageController.text.trim()),
    );
    if (!mounted) return;

    if (captureBaselineNext) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BaselineCaptureScreen(patientId: patient.id, patientName: patient.name),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _nameController.text.trim().isNotEmpty && !_saving;

    return Scaffold(
      appBar: AppBar(title: const Text('Onboard patient')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Age (optional)'),
          ),
          const SizedBox(height: 20),
          const Text('Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _languages
                .map(
                  (lang) => ChoiceChip(
                    label: Text(lang),
                    selected: _language == lang,
                    onSelected: (_) => setState(() => _language = lang),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            onPressed: canSave ? () => _save(captureBaselineNext: true) : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Save and capture baseline'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: canSave ? () => _save(captureBaselineNext: false) : null,
            child: const Text('Save without baseline for now'),
          ),
          const SizedBox(height: 12),
          Text(
            'Without a baseline her sessions are still logged, but no trend can be calculated — '
            'she has nothing of her own to be compared against yet.',
            style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
