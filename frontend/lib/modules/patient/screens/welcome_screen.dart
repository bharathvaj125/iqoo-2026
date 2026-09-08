import 'package:flutter/material.dart';
import 'package:smriti/core/theme.dart';
import '../services/companion.dart';
import '../../../widgets/companion_widget.dart';
import '../utils/patient_page_route.dart';
import 'profile_select_screen.dart';

/// First thing the elder sees when the app opens — the companion
/// character greets her by voice (TTS) with lip-synced mouth
/// movement, instead of a cold login form. This sets the
/// "Comfort-First" tone from the deck before we ever ask her to
/// pick a profile.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _caption = 'Hello there! 👋';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _greet());
  }

  Future<void> _greet() async {
    setState(() => _caption = "It's me, your little grandchild!");
    await Companion.instance.say('greeting');
    if (mounted) {
      setState(() => _caption = 'Ready to play some fun games today?');
    }
  }

  void _goToProfiles() {
    Navigator.pushReplacement(
      context,
      PatientPageRoute(builder: (_) => const ProfileSelectScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const Spacer(flex: 2),
              ListenableBuilder(
                listenable: Companion.instance.controller,
                builder: (context, _) {
                  return CompanionWidget(
                    expression: Companion.instance.controller.expression,
                    size: 250,
                  );
                },
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                layoutBuilder: (currentChild, previousChildren) => currentChild ?? const SizedBox.shrink(),
                child: Padding(
                  key: ValueKey(_caption),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _caption,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: AppColors.primary, fontSize: 26),
                  ),
                ),
              ),
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: ElevatedButton(
                  onPressed: _goToProfiles,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Let's Start"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
