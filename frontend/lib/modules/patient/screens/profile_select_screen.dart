import 'package:flutter/material.dart';
import '../services/local_store.dart';
import 'package:smriti/core/theme.dart';
import '../widgets/companion_corner.dart';
import '../utils/patient_page_route.dart';
import 'voice_checkin_screen.dart';

/// Caregiver opens app, picks profile + language.
/// Zero typing required — photo tiles only, addressing the
/// "language & literacy barrier" viability point from the deck.
class ProfileSelectScreen extends StatelessWidget {
  const ProfileSelectScreen({super.key});

  static final List<ElderProfile> demoProfiles = [
    ElderProfile(
        id: 'p1',
        name: 'Ema (Grandmother)',
        photoAsset: '👵🏽',
        language: 'Assamese',
        state: 'Assam'),
    ElderProfile(
        id: 'p2',
        name: 'Apa (Grandfather)',
        photoAsset: '👴🏽',
        language: 'Khasi',
        state: 'Meghalaya'),
  ];

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
                  const SizedBox(height: 24),
                  const Icon(Icons.favorite, color: AppColors.accent, size: 48),
                  const SizedBox(height: 12),
                  Text('Who is playing today?',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 32),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      children: demoProfiles
                          .map((p) => _ProfileTile(profile: p))
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

class _ProfileTile extends StatefulWidget {
  final ElderProfile profile;
  const _ProfileTile({required this.profile});

  @override
  State<_ProfileTile> createState() => _ProfileTileState();
}

class _ProfileTileState extends State<_ProfileTile> {
  double _scale = 1.0;

  Future<void> _select(BuildContext context) async {
    await LocalStore().saveActiveProfile(widget.profile);
    if (!context.mounted) return;
    Navigator.push(
      context,
      PatientPageRoute(builder: (_) => VoiceCheckInScreen(profile: widget.profile)),
    );
  }

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
            onTap: () => _select(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.profile.photoAsset, style: const TextStyle(fontSize: 72)),
                  const SizedBox(height: 12),
                  Text(widget.profile.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(widget.profile.language,
                      style: const TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
