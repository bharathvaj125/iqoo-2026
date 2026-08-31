import 'package:flutter/material.dart';
import '../services/local_store.dart';
import 'package:smriti/core/theme.dart';
import 'home_screen.dart';

/// "Comfort-First Session": a familiar voice greets her, then a
/// simple voice-guided check-in on mood and routine (no typing,
/// no forms — tap the picture that matches how she feels).
class VoiceCheckInScreen extends StatefulWidget {
  final ElderProfile profile;
  const VoiceCheckInScreen({super.key, required this.profile});

  @override
  State<VoiceCheckInScreen> createState() => _VoiceCheckInScreenState();
}

class _VoiceCheckInScreenState extends State<VoiceCheckInScreen> {
  final moods = const [
    ('😊', 'Happy'),
    ('😐', 'Okay'),
    ('😔', 'Low'),
    ('😣', 'Not well'),
  ];

  Future<void> _pickMood(String mood) async {
    // In production: mood is logged + sent through the Companion
    // Dialogue Service / Caregiver Alert & Sync path shown in the
    // architecture diagram. Low/Not-well moods can raise a soft
    // caregiver notification without alarming the elder.
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => HomeScreen(profile: widget.profile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(widget.profile.photoAsset,
                    style: const TextStyle(fontSize: 48)),
              ),
              const SizedBox(height: 16),
              Text('Good day, ${widget.profile.name.split(' ').first}!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.volume_up, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('How are you feeling today?',
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: moods
                      .map((m) => _MoodTile(
                          emoji: m.$1,
                          label: m.$2,
                          onTap: () => _pickMood(m.$2)))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodTile extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _MoodTile(
      {required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
