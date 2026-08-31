import 'package:flutter/material.dart';
import '../models/patient_models.dart';
import '../services/local_store.dart';
import 'package:smriti/core/theme.dart';
import '../widgets/streak_badge_bar.dart';
import '../widgets/daily_living_card.dart';
import 'comfort_intro_screen.dart';
import 'game_hub_screen.dart';
import 'reminders_screen.dart';
import 'family_screen.dart';
import 'distress_dialog.dart';
import 'companion_screen.dart';
import 'personal_fact_entry_screen.dart';

/// Elder's own home screen — her own phone, her own time.
/// Big icon tiles, minimal text, one clear "Goal" (not a score),
/// and an always-visible help button.
class HomeScreen extends StatefulWidget {
  final ElderProfile profile;
  const HomeScreen({super.key, required this.profile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _goal = '';
  DailyLivingPrompt? _dueDailyLiving;

  @override
  void initState() {
    super.initState();
    _loadGoal();
    _loadDailyLiving();
  }

  Future<void> _loadGoal() async {
    final g = await LocalStore().getDailyGoal();
    setState(() => _goal = g);
  }

  // Phase 3 — Daily Living Guidance: surfaces at most one fixed-set
  // scenario per time-of-day bucket, distinct from scored gameplay and
  // from caregiver-scheduled reminders.
  Future<void> _loadDailyLiving() async {
    final due = await LocalStore().getDueDailyLivingPrompt();
    if (mounted) setState(() => _dueDailyLiving = due);
  }

  Future<void> _openGames() async {
    // Phase 2 personalization loop: occasionally slip a casual, non-testing
    // "tell me about yourself" prompt in between games rather than forcing
    // it every time — spec explicitly frames this as a light moment, not
    // a required step before play.
    final offerCasualPrompt = await LocalStore().shouldOfferCasualFactPrompt();
    if (offerCasualPrompt && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PersonalFactEntryScreen(profile: widget.profile)),
      );
    }
    if (!mounted) return;

    final seenToday = await LocalStore().hasSeenComfortIntroToday();
    if (!mounted) return;
    if (seenToday) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GameHubScreen(profile: widget.profile)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ComfortIntroScreen(profile: widget.profile)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            if (_dueDailyLiving != null)
              DailyLivingCard(
                patientId: widget.profile.id,
                prompt: _dueDailyLiving!,
                onDismissed: () => setState(() => _dueDailyLiving = null),
              ),
            _buildGoalBanner(context),
            StreakBadgeBar(patientId: widget.profile.id),
            const SizedBox(height: 8),
            Expanded(child: _buildTileGrid(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(widget.profile.photoAsset, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Namaskar, ${widget.profile.name.split(' ').first}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          // Always-visible distress / SOS button — never buried in a menu.
          GestureDetector(
            onTap: () => showDistressDialog(context, widget.profile),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.distress,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sos, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_circle, color: AppColors.accent, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's goal",
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                Text(_goal.isEmpty ? 'Loading…' : _goal,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTileGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: [
          _HomeTile(
            icon: Icons.extension,
            label: 'Play Games',
            color: AppColors.primary,
            onTap: _openGames,
          ),
          _HomeTile(
            icon: Icons.notifications_active,
            label: 'Reminders',
            color: AppColors.success,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RemindersScreen()),
            ),
          ),
          _HomeTile(
            icon: Icons.people_alt,
            label: 'My Family',
            color: AppColors.accent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => FamilyScreen(profile: widget.profile)),
            ),
          ),
          _HomeTile(
            icon: Icons.emoji_emotions,
            label: 'Talk to Me',
            color: const Color(0xFF7B5EA7),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompanionScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HomeTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 3,
      shadowColor: AppColors.cardShadow,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 14),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
