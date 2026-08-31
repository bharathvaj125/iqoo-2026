import 'package:flutter/material.dart';
import 'package:smriti/core/theme.dart';

/// A warm, shimmering placeholder — use in place of a bare `CircularProgressIndicator`
/// for a page/section that's waiting on data, per the design system. Neither
/// ASHA/Caregiver screen currently has a full-page loading state to replace (both
/// modules read from an already-loaded local repository, never a live network call
/// mid-render), so this exists as ready-to-use infrastructure for whenever one shows
/// up — e.g. once ASHA/Caregiver screens read from the backend instead of only local
/// storage. The three small in-button spinners in this codebase today (baseline
/// capture, session end, save reminder) are a different, unrelated pattern — "this
/// specific button is mid-tap" is not the same thing as "this screen has no content
/// yet," and forcing a full skeleton into a 20px button would look wrong, not better.
///
/// Usage: `SkeletonBox(width: double.infinity, height: 80)` for a single placeholder
/// shape, or wrap several in a `Column`/`Row` to sketch out a card's real layout.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(AppColors.divider, AppColors.surfaceRaised, t),
            borderRadius: widget.borderRadius,
          ),
        );
      },
    );
  }
}

/// A ready-made "card with a couple of lines of text" skeleton, sized to stand in for
/// the list rows this app actually uses (session cards, patient tiles, reminder cards).
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SkeletonBox(width: 44, height: 44, borderRadius: BorderRadius.all(Radius.circular(22))),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 160, height: 18),
                  SizedBox(height: 8),
                  SkeletonBox(width: 100, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
