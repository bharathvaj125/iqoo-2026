import 'package:flutter/material.dart';
import '../services/local_store.dart';
import 'package:smriti/core/theme.dart';
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
        child: Padding(
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
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final ElderProfile profile;
  const _ProfileTile({required this.profile});

  Future<void> _select(BuildContext context) async {
    await LocalStore().saveActiveProfile(profile);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VoiceCheckInScreen(profile: profile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _select(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(profile.photoAsset, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 12),
              Text(profile.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(profile.language,
                  style: const TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
