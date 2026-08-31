import 'package:flutter/material.dart';
import '../services/local_store.dart';
import 'package:smriti/core/theme.dart';
import '../widgets/companion_corner.dart';
import '../utils/patient_page_route.dart';
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
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PatientPageRoute(
          builder: (_) => HomeScreen(profile: widget.profile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
            const Positioned(
              top: 8,
              right: 12,
              child: CompanionCorner(size: 56),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodTile extends StatefulWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _MoodTile(
      {required this.emoji, required this.label, required this.onTap});

  @override
  State<_MoodTile> createState() => _MoodTileState();
}

class _MoodTileState extends State<_MoodTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          elevation: 3,
          shadowColor: AppColors.cardShadow,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text(widget.label, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
