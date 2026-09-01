import 'package:flutter/material.dart';

/// The locked design system for this app — every value here is taken directly
/// from the approved design brief, not chosen freely. Do not introduce new
/// colours or swap these for "close enough" alternatives; if a screen seems to
/// need one, it's a sign the layout needs rethinking, not the palette.
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
/// * **Never red, anywhere, for any state, including errors** — in every
///   module, not just the Patient module. This is a deliberate accessibility
///   and zero-frustration decision (see [distress]), not a style preference.
/// * **Colour is never the only signal.** Every state that uses colour in this
///   app is also carried by an icon, a label, or both — colour vision loss
///   shouldn't cost the user information.
class AppColors {
  AppColors._();

  /// Warm ivory. Lower glare than #FFFFFF while keeping text contrast high.
  static const Color surface = Color(0xFFFAF6EC);

  /// Slightly deeper ivory for cards that need to separate from the page
  /// without a shadow doing the work.
  static const Color surfaceRaised = Color(0xFFF1EADA);

  /// Deep teal-green. Calm and non-clinical, dark enough to carry white text,
  /// and far from [accent] in both hue and luminance.
  static const Color primary = Color(0xFF1F4A3D);

  /// Turmeric gold / warm amber, darkened until it holds contrast as text on
  /// [surface].
  static const Color accent = Color(0xFFC98A2E);

  /// Reserved exclusively for the companion character (see
  /// widgets/companion_widget.dart) — never use this for a functional UI
  /// element. Not part of the app chrome palette; listed here only so nothing
  /// else accidentally reuses it.
  static const Color companionOnly = Color(0xFF8FB9C4);

  /// Pale gold-cream. A background wash for a positive/on-track state — e.g.
  /// an "everything's on schedule" card — not a foreground icon/text/button
  /// colour; it's too light for that role against [surface].
  static const Color success = Color(0xFFE8DCC0);

  /// Strong positive confirmation signal — checkmarks, completion badges,
  /// "acknowledged" icons. The same hue as [primary] rather than a separate
  /// green, so a confirmed state reads as "on-brand calm", not "test passed".
  static const Color successAccent = primary;

  /// Warm near-black. Pure black on ivory reads harsher than this.
  static const Color textPrimary = Color(0xFF1B2A41);
  static const Color textSecondary = Color(0xFF4C5A6E);

  /// Needs-attention states (a missed session, falling adherence, an open
  /// trend flag, the Patient module's SOS). Deliberately the *same* gold as
  /// [accent] rather than a separate hue — the locked palette has no
  /// dedicated "warning"/"danger" colour, and red is banned even for errors,
  /// in every module. Every call site pairs this with an icon or label, per
  /// the colour-is-never-the-only-signal rule above, so reusing accent's hue
  /// doesn't cost legibility even where it sits next to an actual
  /// accent-coloured CTA.
  static const Color distress = accent;

  static const Color divider = Color(0xFFE0D6C0);
  static const Color cardShadow = Color(0x14000000);

  // --- Aliases so both halves of the codebase compile against whichever
  // name they were written against, without renaming call sites. ---
  static const Color danger = distress;
  static const Color bgSoft = surface;
  static const Color softSuccessBackground = success;
  static const Color companionBody = companionOnly;
}

/// Two densities over one palette and one type system.
///
/// The worker-facing dashboards show rosters and tables to a sighted ASHA on a
/// tablet; the elder-facing screens show one thing at a time to someone who may
/// have low vision and low literacy. Same colours, same fonts, same minimum
/// sizes — only layout density differs, never the type system itself, so the
/// app reads as one product rather than two people's separate guesses.
class AppTheme {
  AppTheme._();

  static const Color primary = AppColors.primary;
  static const Color accent = AppColors.accent;
  static const Color danger = AppColors.distress;
  static const Color surface = AppColors.surface;

  /// Headings and buttons, per the design system. Falls back to the actual
  /// script fonts below for any glyph Poppins doesn't cover (Bengali script
  /// for Assamese, Meetei Mayek for Manipuri) — this is what makes a heading
  /// stay legible when the active locale is `as`/`mni` without the theme
  /// needing to know the current locale itself.
  static const _headingFontFamily = 'Poppins';

  /// Body text and all multilingual content, per the design system.
  static const _bodyFontFamily = 'Noto Sans';

  /// Script fonts for text this app actually authors (Bengali for Assamese,
  /// Meetei Mayek for Manipuri), plus a bundled colour emoji font. Naming an
  /// OS-installed font like "Segoe UI Emoji" here does *not* work — web runs
  /// on the CanvasKit renderer, which paints the whole app onto one canvas via
  /// Skia's own font manager and has no way to reach an OS font by name the
  /// way a real browser's HTML text does. Without an actual bundled emoji
  /// font, every emoji the Patient module uses (profile avatars, Picture
  /// Recall's items, mood faces) renders as a generic missing-glyph
  /// placeholder instead of the intended picture — confirmed by inspecting
  /// the live DOM, not by reading the code. Confirmed live that this engine's
  /// CanvasKit build renders COLR colour glyphs correctly, so this bundles
  /// the real colour font rather than a monochrome stand-in.
  static const _scriptFallbacks = [
    'Noto Sans Bengali',
    'Noto Sans Meetei Mayek',
    'Noto Color Emoji',
  ];

  /// ASHA and caregiver dashboards: data-dense, professional-facing surfaces.
  /// These don't need the Patient module's one-decision-per-screen layout
  /// constraint, but they use the exact same colours, fonts, and minimum
  /// sizes it does.
  static ThemeData get light => _build(
        bodyMedium: 20,
        bodyLarge: 22,
        bodySmall: 18,
        titleMedium: 24,
        titleLarge: 28,
        headline: 32,
        primaryButtonText: 28,
        secondaryButtonText: 20,
        minButtonHeight: 56,
        radius: 14,
      );

  /// Patient-facing. Larger still, and taller tap targets — a target this
  /// size survives a hand that isn't steady.
  static ThemeData get elder => _build(
        bodyMedium: 24,
        bodyLarge: 26,
        bodySmall: 20,
        titleMedium: 28,
        titleLarge: 32,
        headline: 36,
        primaryButtonText: 32,
        secondaryButtonText: 24,
        minButtonHeight: 72,
        radius: 20,
      );

  static ThemeData _build({
    required double bodyMedium,
    required double bodyLarge,
    required double bodySmall,
    required double titleMedium,
    required double titleLarge,
    required double headline,
    required double primaryButtonText,
    required double secondaryButtonText,
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
      fontFamily: _bodyFontFamily,
      fontFamilyFallback: _scriptFallbacks,
    );

    TextStyle body(double size, {FontWeight weight = FontWeight.normal}) => TextStyle(
          fontFamily: _bodyFontFamily,
          fontFamilyFallback: _scriptFallbacks,
          fontSize: size,
          fontWeight: weight,
          color: AppColors.textPrimary,
        );

    TextStyle heading(double size, {FontWeight weight = FontWeight.w600}) => TextStyle(
          fontFamily: _headingFontFamily,
          fontFamilyFallback: _scriptFallbacks,
          fontSize: size,
          fontWeight: weight,
          color: AppColors.textPrimary,
        );

    return base.copyWith(
      textTheme: TextTheme(
        displayLarge: heading(headline + 8, weight: FontWeight.w700),
        displayMedium: heading(headline + 4, weight: FontWeight.w700),
        displaySmall: heading(headline, weight: FontWeight.w700),
        headlineLarge: heading(headline, weight: FontWeight.w700),
        headlineMedium: heading(titleLarge + 2, weight: FontWeight.w700),
        headlineSmall: heading(titleLarge, weight: FontWeight.w700),
        titleLarge: heading(titleLarge),
        titleMedium: heading(titleMedium),
        titleSmall: heading(bodyLarge),
        bodyLarge: body(bodyLarge),
        bodyMedium: body(bodyMedium),
        bodySmall: body(bodySmall),
        labelLarge: heading(secondaryButtonText, weight: FontWeight.w600),
        labelMedium: heading(bodySmall, weight: FontWeight.w600),
        labelSmall: heading(bodySmall - 2, weight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(64, minButtonHeight),
          textStyle: TextStyle(
            fontFamily: _headingFontFamily,
            fontFamilyFallback: _scriptFallbacks,
            fontSize: primaryButtonText,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(64, minButtonHeight),
          // A visible border is what separates "you can press this" from plain
          // text for someone who can't rely on subtle colour differences.
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: TextStyle(
            fontFamily: _headingFontFamily,
            fontFamilyFallback: _scriptFallbacks,
            fontSize: secondaryButtonText,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: TextStyle(
            fontFamily: _headingFontFamily,
            fontFamilyFallback: _scriptFallbacks,
            fontSize: secondaryButtonText,
            fontWeight: FontWeight.w600,
          ),
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
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: heading(titleMedium, weight: FontWeight.w700),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: body(bodyMedium, weight: FontWeight.normal).copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }
}
