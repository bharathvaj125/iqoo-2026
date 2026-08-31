import 'package:flutter/material.dart';
import '../../../../widgets/companion_widget.dart';
import '../services/companion.dart';

/// Small, non-blocking companion widget positioned in the corner of a screen.
/// Listens to [Companion.instance.controller] live so any expression updates
/// automatically repaint the character. Tapping it plays a gentle 'question' prompt.
class CompanionCorner extends StatelessWidget {
  final double size;

  const CompanionCorner({
    super.key,
    this.size = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Companion.instance.say('question'),
      child: Container(
        width: size + 8,
        height: size + 8,
        alignment: Alignment.center,
        child: ListenableBuilder(
          listenable: Companion.instance.controller,
          builder: (context, _) {
            return CompanionWidget(
              expression: Companion.instance.controller.expression,
              size: size,
            );
          },
        ),
      ),
    );
  }
}
