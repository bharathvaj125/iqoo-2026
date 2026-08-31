import 'package:flutter/material.dart';
import 'package:smriti/core/locale_controller.dart';
import 'package:smriti/core/theme.dart';

/// Drop this into any module's onboarding/settings screen to let the user change
/// the app's language. Self-contained: it reads and writes
/// [AppLocaleController.instance] directly, so no screen needs to hold locale state
/// or thread a callback through — adding it to a screen is exactly
/// `const LanguageSelector()`, nothing else to wire up.
///
/// Not used anywhere in the app yet (see docs/FEATURES.md) — each module owner
/// drops it into their own onboarding/settings screen when that's their task.
///
/// Every option label pairs the language's own autonym with an English gloss
/// (e.g. "बड़ो · Bodo") rather than the script alone, since a tester who doesn't
/// read that script still needs to know which option they picked.
class LanguageSelector extends StatelessWidget {
  /// Set false to render just the dropdown with no "Language" caption above it —
  /// useful when the surrounding screen already provides its own section heading.
  final bool showLabel;

  const LanguageSelector({super.key, this.showLabel = true});

  static const _options = <_LanguageOption>[
    _LanguageOption(locale: null, autonym: 'System default', gloss: null),
    _LanguageOption(locale: Locale('en'), autonym: 'English', gloss: null),
    _LanguageOption(locale: Locale('as'), autonym: 'অসমীয়া', gloss: 'Assamese'),
    _LanguageOption(locale: Locale('brx'), autonym: 'बड़ो', gloss: 'Bodo'),
    _LanguageOption(locale: Locale('mni'), autonym: 'মৈতৈলোন্', gloss: 'Manipuri'),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: AppLocaleController.instance,
      builder: (context, currentLocale, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLabel) ...[
              const Text(
                'Language',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
            ],
            DropdownButtonFormField<Locale?>(
              value: currentLocale,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              items: _options
                  .map(
                    (option) => DropdownMenuItem<Locale?>(
                      value: option.locale,
                      child: Text(option.label),
                    ),
                  )
                  .toList(),
              onChanged: (locale) => AppLocaleController.instance.setLocale(locale),
            ),
          ],
        );
      },
    );
  }
}

class _LanguageOption {
  final Locale? locale;
  final String autonym;
  final String? gloss;

  const _LanguageOption({required this.locale, required this.autonym, required this.gloss});

  String get label => gloss == null ? autonym : '$autonym · $gloss';
}
