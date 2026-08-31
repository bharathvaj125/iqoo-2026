import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/l10n_gen/app_localizations.dart';

/// Proves the localization pipeline actually resolves a translated string per
/// locale end to end (delegate -> lookup -> generated class), independent of
/// whether it's visible anywhere in the running app yet (see lib/l10n/README.md —
/// no screen has been migrated to use AppLocalizations yet).
///
/// Loads AppLocalizations.delegate directly rather than pumping a full
/// MaterialApp: MaterialApp's Localizations widget also validates every
/// *framework* delegate (Material/Cupertino) against the locale, and Flutter's
/// own button/date-picker strings genuinely have no translation for as/brx/mni
/// — that's a real, separate limitation (see lib/l10n/README.md), not something
/// this test should fail on when all it's checking is our own AppLocalizations.
void main() {
  test('appTitle resolves to a distinct, correct string for each supported locale', () async {
    expect((await AppLocalizations.delegate.load(const Locale('en'))).appTitle, 'Smriti');
    expect((await AppLocalizations.delegate.load(const Locale('as'))).appTitle, 'স্মৃতি');
    expect((await AppLocalizations.delegate.load(const Locale('brx'))).appTitle, 'स्मृति');
    expect((await AppLocalizations.delegate.load(const Locale('mni'))).appTitle, 'স্মৃতি');
  });

  test('the delegate only claims to support the four locales we actually ship', () {
    for (final code in ['en', 'as', 'brx', 'mni']) {
      expect(AppLocalizations.delegate.isSupported(Locale(code)), isTrue, reason: code);
    }
    expect(AppLocalizations.delegate.isSupported(const Locale('fr')), isFalse);
  });
}
