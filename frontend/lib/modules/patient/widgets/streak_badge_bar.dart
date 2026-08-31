import 'package:flutter/material.dart';

import '../models/patient_models.dart';
import '../services/local_store.dart';
import 'package:smriti/core/theme.dart';

/// Shows the current streak and any earned badges. Deliberately shows
/// no accuracy, no score, no ranking — just consistency and effort,
/// per the spec's zero-failure design.
class StreakBadgeBar extends StatefulWidget {
  final String patientId;
  const StreakBadgeBar({super.key, required this.patientId});

  @override
  State<StreakBadgeBar> createState() => _StreakBadgeBarState();
}

class _StreakBadgeBarState extends State<StreakBadgeBar> {
  Streak? _streak;
  List<RewardBadge> _badges = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final streak = await LocalStore().getStreak(widget.patientId);
    final badges = await LocalStore().getBadges(widget.patientId);
    if (mounted) setState(() {
      _streak = streak;
      _badges = badges;
    });
  }

  @override
  Widget build(BuildContext context) {
    final streak = _streak;
    if (streak == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              streak.currentStreakDays == 0
                  ? 'Play today to start a streak!'
                  : '${streak.currentStreakDays}-day streak',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          if (_badges.isNotEmpty)
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _badges
                    .map((b) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Tooltip(
                            message: b.label,
                            child: Text(b.emoji, style: const TextStyle(fontSize: 24)),
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
