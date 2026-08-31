import 'package:flutter/material.dart';

import '../services/companion.dart';
import '../services/local_store.dart';
import 'package:smriti/core/theme.dart';
import '../../../widgets/companion_widget.dart';
import '../utils/patient_page_route.dart';
import 'game_hub_screen.dart';

/// Shown once per calendar day, before the first game — a short,
/// warm framing moment so the patient never feels like their memory is
/// about to be tested. Per the spec this is explicitly *not* skippable
/// via a settings toggle; it just naturally only shows once a day.
class ComfortIntroScreen extends StatefulWidget {
  final ElderProfile profile;
  const ComfortIntroScreen({super.key, required this.profile});

  @override
  State<ComfortIntroScreen> createState() => _ComfortIntroScreenState();
}

class _ComfortIntroScreenState extends State<ComfortIntroScreen> {
  int _step = 0;
  final _lines = const [
    'comfort_intro_1',
    'comfort_intro_2',
    'comfort_intro_3',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrent());
  }

  Future<void> _speakCurrent() async {
    await Companion.instance.say(_lines[_step]);
  }

  Future<void> _next() async {
    if (_step < _lines.length - 1) {
      setState(() => _step += 1);
      await _speakCurrent();
    } else {
      await LocalStore().markComfortIntroShownToday();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PatientPageRoute(
          builder: (_) => GameHubScreen(profile: widget.profile),
        ),
      );
    }
  }

  static const _captions = [
    "Hello! I'm so happy you're here today. 🌼",
    "We're just going to play and chat together for a little while —\nnice and slow, no hurry at all.",
    "Whenever you're ready, let's begin!",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            ListenableBuilder(
              listenable: Companion.instance.controller,
              builder: (context, _) {
                return CompanionWidget(
                  expression: Companion.instance.controller.expression,
                  size: 240,
                );
              },
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Padding(
                key: ValueKey(_step),
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _captions[_step],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _step < _lines.length - 1 ? 'Okay' : "Let's play!",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
