import 'package:flutter/material.dart';
import '../services/companion.dart';
import '../widgets/companion_character.dart';
import 'package:smriti/core/theme.dart';

/// Demo screen for the full pipeline described in the brief:
///   User -> Flutter App -> (AI) response -> Text -> TTS -> character
///   speaks with mouth-state lip sync and situation-driven expression.
///
/// The quick-action buttons stand in for real triggers elsewhere in
/// the app (greeting on launch, a correct/wrong answer in a game,
/// game completion, a reminder firing, etc). The text field simulates
/// a free-form "ask the companion" interaction.
class CompanionScreen extends StatefulWidget {
  const CompanionScreen({super.key});

  @override
  State<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends State<CompanionScreen> {
  final _textController = TextEditingController();
  bool _busy = false;

  Future<void> _trigger(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    await action();
    if (mounted) setState(() => _busy = false);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companion = Companion.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuzu • My Companion'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              '3D Kuzu is with you',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            CompanionCharacter(controller: companion.controller, size: 220),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _ActionChip('👋 Greeting', () => companion.say('greeting')),
                  _ActionChip('❓ Ask Question', () => companion.say('question')),
                  _ActionChip('✅ Correct Answer', () => companion.say('correct')),
                  _ActionChip('🙂 Wrong Answer', () => companion.say('wrong')),
                  _ActionChip('🧠 Memory Exercise', () => companion.say('memory_exercise')),
                  _ActionChip('😌 User Confused', () => companion.say('user_confused')),
                  _ActionChip('🎉 Game Completed', () => companion.say('game_completed')),
                ].map((chip) => chip.build(context, _busy, _trigger)).toList(),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type something to ask your companion…',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.accent,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _busy
                          ? null
                          : () {
                              final text = _textController.text;
                              _textController.clear();
                              _trigger(() => companion.sayFreeText(text));
                            },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip {
  final String label;
  final Future<void> Function() onTap;
  _ActionChip(this.label, this.onTap);

  Widget build(BuildContext context, bool busy, Future<void> Function(Future<void> Function()) trigger) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 15)),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
      ),
      onPressed: busy ? null : () => trigger(onTap),
    );
  }
}
