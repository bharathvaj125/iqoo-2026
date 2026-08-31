import 'package:flutter/material.dart';

/// Smooth, gentle page route with subtle slide and fade transition (~260ms),
/// tuned for the elder-facing Patient module to avoid abrupt or jarring cuts.
class PatientPageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  PatientPageRoute({
    required this.builder,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
