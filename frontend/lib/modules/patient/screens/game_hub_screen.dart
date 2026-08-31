import 'package:flutter/material.dart';

import '../services/local_store.dart';
import 'package:smriti/core/theme.dart';
import '../widgets/companion_corner.dart';
import '../utils/patient_page_route.dart';
import 'game_screen.dart';
import 'picture_recall_screen.dart';
import 'reminiscence_recall_screen.dart';

/// Pre-built games list the companion leads into after the comfort
/// intro. Kept as big warm tiles, no scores or difficulty shown here —
/// difficulty adapts silently behind the scenes per game.
class GameHubScreen extends StatelessWidget {
  final ElderProfile profile;
  const GameHubScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Game'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: [
                _GameTile(
                  emoji: '🖼️',
                  label: 'Picture Recall',
                  color: AppColors.primary,
                  onTap: () => Navigator.push(
                    context,
                    PatientPageRoute(
                      builder: (_) => PictureRecallScreen(profile: profile),
                    ),
                  ),
                ),
                _GameTile(
                  emoji: '🃏',
                  label: 'Memory Match',
                  color: AppColors.accent,
                  onTap: () => Navigator.push(
                    context,
                    PatientPageRoute(
                      builder: (_) => GameScreen(profile: profile),
                    ),
                  ),
                ),
                _GameTile(
                  emoji: '💭',
                  label: 'Remember With Me',
                  color: const Color(0xFF7B5EA7),
                  onTap: () => Navigator.push(
                    context,
                    PatientPageRoute(
                      builder: (_) => ReminiscenceRecallScreen(profile: profile),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 4,
            right: 12,
            child: CompanionCorner(size: 52),
          ),
        ],
      ),
    );
  }
}

class _GameTile extends StatefulWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GameTile({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_GameTile> createState() => _GameTileState();
}

class _GameTileState extends State<_GameTile> {
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
                CircleAvatar(
                  radius: 40,
                  backgroundColor: widget.color.withValues(alpha: 0.15),
                  child: Text(widget.emoji, style: const TextStyle(fontSize: 40)),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
