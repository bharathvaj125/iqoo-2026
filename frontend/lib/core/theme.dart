import 'package:flutter/material.dart';

/// One palette for all three modules.
///
/// The choices here are driven by how ageing and dementia actually change
/// vision and attention, not by taste:
///
/// * **The lens yellows with age**, which compresses discrimination at the blue
///   and violet end. Warm hues and, more importantly, large *luminance* gaps
///   survive that far better — so no two meaningful colours here are separated
///   by hue alone, and the two most-used ones (teal, amber) differ in both.
/// * **Contrast sensitivity drops**, so text sits at a high ratio against its
///   background — but on a warm ivory rather than pure white, because a bright
///   white field is a common source of glare and visual fatigue for older eyes.
/// * **Red is arousing.** It is reserved for genuine distress and for the
///   caregiver's "needs attention" states; it is never decoration.
/// * **Colour is never the only signal.** Every state that uses colour in this
///   app is also carried by an icon, a label, or both — colour vision loss
///   shouldn't cost the user information.
class AppColors {
  AppColors._();

  /// Warm ivory. Lower glare than #FFFFFF while keeping text contrast high.
  static const Color surface = Color(0xFFFAF6EE);

  /// Slightly deeper ivory for cards that need to separate from the page
  /// without a shadow doing the work.
  static const Color surfaceRaised = Color(0xFFF3EDE1);

  /// Deep teal-green. Calm and non-clinical, dark enough to carry white text,
  /// and far from [accent] in both hue and luminance.
  static const Color primary = Color(0xFF1F5F52);

  /// Warm amber, darkened until it holds contrast as text on [surface].
  static const Color accent = Color(0xFFC4671E);

  static const Color success = Color(0xFF2E6B3E);

  /// Genuine distress and caregiver "needs attention" only.
  static const Color distress = Color(0xFFA8321C);

  /// Warm near-black. Pure black on ivory reads harsher than this.
  static const Color textPrimary = Color(0xFF1A1714);
  static const Color textSecondary = Color(0xFF4A423B);

  static const Color divider = Color(0xFFDDD3C2);
  static const Color cardShadow = Color(0x14000000);

  // --- Aliases so both halves of the codebase compile unchanged ---
  // The ASHA/caregiver modules were written against `danger`; the patient
  // module against `bgSoft`. Same colours, one definition.
  static const Color danger = distress;
  static const Color bgSoft = surface;
}

/// Two densities over one palette.
///
/// The worker-facing dashboards show rosters and tables to a sighted ASHA on a
/// tablet; the elder-facing screens show one thing at a time to someone who may
/// have low vision and low literacy. Same colours and shapes, different scale —
/// so the app reads as one product without making the patient squint at
/// dashboard-sized type.
class AppTheme {
  AppTheme._();

  static const Color primary = AppColors.primary;
  static const Color accent = AppColors.accent;
  static const Color danger = AppColors.distress;
  static const Color surface = AppColors.surface;

  /// ASHA and caregiver dashboards.
  static ThemeData get light => _build(textScale: 1.05, minButtonHeight: 56, radius: 14);

  /// Patient-facing. Larger type, taller targets, rounder shapes — a tap target
  /// this size survives a hand that isn't steady.
  static ThemeData get elder => _build(textScale: 1.45, minButtonHeight: 72, radius: 20);

  static ThemeData _build({
    required double textScale,
    required double minButtonHeight,
    required double radius,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.distress,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.surface,
    );

    return base.copyWith(
      textTheme: _scaled(base.textTheme, textScale).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(64, minButtonHeight),
          textStyle: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(64, minButtonHeight),
          // A visible border is what separates "you can press this" from plain
          // text for someone who can't rely on subtle colour differences.
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: TextStyle(fontSize: 15 * textScale, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius + 2),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: TextStyle(fontSize: 15 * textScale, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }

  /// `TextTheme.apply(fontSizeFactor:)` asserts when any base style has a null
  /// fontSize, which some Material 3 defaults do on this Flutter version.
  /// Scale explicitly, defaulting a missing size to 14 first.
  static TextTheme _scaled(TextTheme base, double factor) {
    TextStyle? scale(TextStyle? style) =>
        style?.copyWith(fontSize: (style.fontSize ?? 14.0) * factor);

    return base.copyWith(
      displayLarge: scale(base.displayLarge),
      displayMedium: scale(base.displayMedium),
      displaySmall: scale(base.displaySmall),
      headlineLarge: scale(base.headlineLarge),
      headlineMedium: scale(base.headlineMedium),
      headlineSmall: scale(base.headlineSmall),
      titleLarge: scale(base.titleLarge),
      titleMedium: scale(base.titleMedium),
      titleSmall: scale(base.titleSmall),
      bodyLarge: scale(base.bodyLarge),
      bodyMedium: scale(base.bodyMedium),
      bodySmall: scale(base.bodySmall),
      labelLarge: scale(base.labelLarge),
      labelMedium: scale(base.labelMedium),
      labelSmall: scale(base.labelSmall),
    );
  }
}
