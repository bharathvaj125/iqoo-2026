import 'package:flutter/material.dart';

/// A gentle fade + slight upward slide (~280ms), replacing the platform-default
/// page transition (which on Android is an abrupt slide-from-the-right) — used
/// throughout the ASHA and Caregiver modules for a calmer navigation feel, per
/// the design system's "gentle screen transitions" rule. Drop-in replacement
/// for `MaterialPageRoute`: `Navigator.push(context, fadeSlideRoute(builder: ...))`.
Route<T> fadeSlideRoute<T>({required WidgetBuilder builder, RouteSettings? settings}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}
