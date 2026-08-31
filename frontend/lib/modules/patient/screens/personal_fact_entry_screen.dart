import 'package:flutter/material.dart';

import '../models/patient_models.dart';
import '../services/companion.dart';
import '../services/local_store.dart';
import 'package:smriti/core/theme.dart';
import '../widgets/companion_corner.dart';

/// Facilitator-assisted capture of a single Personal Fact — spec's "build
/// this first, works for every language" path: an ASHA or caregiver enters
/// who/what/category via a short structured form during or after a
/// conversation with the patient. No speech recognition needed.
///
/// Direct voice capture (Bhashini/AI4Bharat STT, Assamese/Bodo/Manipuri)
/// is additive per the spec and intentionally not built here — it would
/// sit ahead of this same form as a pre-fill/confirm step, not replace it.
class PersonalFactEntryScreen extends StatefulWidget {
  final ElderProfile profile;
  const PersonalFactEntryScreen({super.key, required this.profile});

  @override
  State<PersonalFactEntryScreen> createState() => _PersonalFactEntryScreenState();
}

class _PersonalFactEntryScreenState extends State<PersonalFactEntryScreen> {
  static const _categories = [
    'gift_from_family',
    'hometown',
    'hobby',
    'pet',
    'festival',
    'food',
    'past_occupation',
    'family_visit',
  ];

  String _category = _categories.first;
  final _entityController = TextEditingController();
  final _valueController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Companion.instance.say('casual_fact_prompt');
    });
  }

  String get _categoryLabel {
    switch (_category) {
      case 'gift_from_family':
        return 'A gift from family';
      case 'hometown':
        return 'Hometown / childhood place';
      case 'hobby':
        return 'A hobby they enjoy';
      case 'pet':
        return 'A pet';
      case 'festival':
        return 'A favourite festival';
      case 'food':
        return 'A favourite food';
      case 'past_occupation':
        return 'What they used to do for work';
      case 'family_visit':
        return 'A recent family visit';
      default:
        return _category;
    }
  }

  Future<void> _save() async {
    if (_entityController.text.trim().isEmpty || _valueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both fields.')),
      );
      return;
    }
    setState(() => _saving = true);
    await LocalStore().savePersonalFact(
      PersonalFact(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        patientId: widget.profile.id,
        category: _category,
        entity: _entityController.text.trim(),
        value: _valueController.text.trim(),
        capturedAt: DateTime.now(),
      ),
    );
    await LocalStore().markCasualFactPromptShown();
    if (!mounted) return;
    await Companion.instance.say('fact_saved_thanks');
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _skip() async {
    await LocalStore().markCasualFactPromptShown();
    if (!mounted) return;
    Navigator.pop(context, false);
  }

  @override
  void dispose() {
    _entityController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tell Me About You'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "This isn't a test — just jot down something they shared, "
                    'so the companion can bring it up warmly next time.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  const Text('What kind of memory is this?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _category,
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(_categoryLabelFor(c))))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v ?? _category),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  const Text('Who / what is it about?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _entityController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. daughter, childhood village, pet dog',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('What did they say?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _valueController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. jasmine flowers, Sivasagar, Bhutu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save this memory'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _saving ? null : _skip, child: const Text('Not right now')),
                ],
              ),
            ),
            const Positioned(
              top: 6,
              right: 12,
              child: CompanionCorner(size: 52),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabelFor(String c) {
    final prev = _category;
    _category = c;
    final label = _categoryLabel;
    _category = prev;
    return label;
  }
}
