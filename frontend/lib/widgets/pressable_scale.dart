import 'package:flutter/material.dart';

/// Wrap any tappable widget to get a visible pressed state — scales down to
/// ~0.96 on press and eases back on release, per the design system. Material's
/// own ripple already gives *some* feedback, but a lot of the tiles in this
/// app (session cards, patient rows, reminder cards) are entire cards with an
/// onTap rather than a button, where a ripple alone reads as barely-there —
/// the scale is what actually reads as "this responded to your touch."
///
/// Purely visual: wrap the existing tappable content, keep its own onTap/
/// InkWell untouched, and pass that same callback here too so this widget
/// knows when a press starts/ends.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressableScale({super.key, required this.child, this.onTap});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return; // nothing to respond to — stay static
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
