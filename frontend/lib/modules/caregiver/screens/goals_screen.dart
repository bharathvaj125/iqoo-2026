import 'package:flutter/material.dart';
import 'package:smriti/core/repository_listener.dart';
import 'package:smriti/core/theme.dart';
import 'package:smriti/modules/caregiver/data/caregiver_repository.dart';
import 'package:smriti/modules/patient/models/patient_models.dart' show DailyLivingPrompt;
import 'package:smriti/widgets/sign_out_button.dart';

const _timeOfDayOptions = ['morning', 'afternoon', 'evening', 'night'];

String _timeOfDayLabel(String value) => switch (value) {
      'morning' => 'Morning',
      'afternoon' => 'Afternoon',
      'evening' => 'Evening',
      'night' => 'Night',
      _ => value,
    };

/// Simple, single-step routine nudges the caregiver sets herself — "make tea",
/// "go to the bathroom at night" — distinct from [RemindersScreen]'s scheduled
/// medicine/hydration/appointment alerts.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> with RepositoryListener {
  final _repo = CaregiverRepository.instance;
  final _textController = TextEditingController();
  String _timeOfDay = 'morning';

  @override
  void initState() {
    super.initState();
    listenTo([_repo.onChange]);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    await _repo.addGoal(text: text, timeOfDay: _timeOfDay);
    _textController.clear();
    if (mounted) FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final goals = _repo.goals;

    return Scaffold(
      appBar: AppBar(title: const Text('Goals'), actions: const [SignOutButton()]),
      // One scrollable list start to finish — the add-goal card's own content (field +
      // chips + button) is already tall enough that splitting it from a separately
      // Expanded goal list overflowed on shorter viewports (a real bug: fixed once here
      // rather than each panel individually, since a caregiver tablet can be either
      // orientation).
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Make a cup of tea',
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _timeOfDayOptions
                        .map(
                          (value) => ChoiceChip(
                            label: Text(_timeOfDayLabel(value)),
                            selected: _timeOfDay == value,
                            onSelected: (_) => setState(() => _timeOfDay = value),
                            selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                      onPressed: _add,
                      child: const Text('Add goal'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: Colors.black.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'These stay on this device for now — reaching her device directly needs a pairing '
                  "step that isn't built yet.",
                  style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (goals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No goals yet. Add one above.')),
            )
          else
            ...goals.map(
              (goal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GoalTile(
                  goal: goal,
                  onToggle: (enabled) => _repo.setGoalEnabled(goal.id, enabled),
                  onDelete: () => _repo.deleteGoal(goal.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final DailyLivingPrompt goal;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _GoalTile({required this.goal, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: goal.enabled ? null : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeOfDayLabel(goal.triggerTimeOfDay),
                    style: TextStyle(fontSize: 13, color: Colors.black.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            Switch(value: goal.enabled, onChanged: onToggle, activeTrackColor: AppTheme.primary),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete goal',
            ),
          ],
        ),
      ),
    );
  }
}
