# Localization (`lib/l10n/`)

Infrastructure only, set up so both teammates can migrate their own module's strings
without stepping on each other. **No real UI strings have been migrated yet** — the whole
app still renders hardcoded English. `appTitle` below is the one exception, wired
end-to-end purely to prove the pipeline works.

## How it works

Standard Flutter i18n: `flutter_localizations` (SDK) + `intl` (already a dependency here)
+ `.arb` files, compiled by `flutter gen-l10n` — which runs automatically on
`flutter pub get` / `flutter run` because `pubspec.yaml` has `flutter: generate: true`.
`l10n.yaml` (frontend root) points it at this folder and tells it to write the generated
`AppLocalizations` class into `lib/l10n_gen/app_localizations.dart` (committed to the
repo, not hidden in a synthetic package, so you can jump to it from your IDE and see it in
diffs like any other generated file).

Four locales, one `.arb` file each, all living in this same folder:

| File | Locale | Language |
|---|---|---|
| `app_en.arb` | `en` | English — **the template file**: every key must exist here first |
| `app_as.arb` | `as` | Assamese |
| `app_brx.arb` | `brx` | Bodo |
| `app_mni.arb` | `mni` | Manipuri (Meitei) |

`app_en.arb` is the template gen-l10n reads the key list from — add a new key there
first (with its `@key` metadata block), then add the same key to the other three files.
A key missing from a non-English file silently falls back to the English string at
runtime, so a half-translated app never shows a blank label — but `flutter gen-l10n`
still runs a completeness check and will warn you about the gap.

## Adding your own string — the pattern to follow

1. Add the key to **all four** `.arb` files in this folder (English gets the `@key`
   description block; the other three just need the key and its translated value).
2. Run `flutter pub get` (or just `flutter run` — it triggers gen-l10n automatically) to
   regenerate `lib/l10n_gen/app_localizations.dart`.
3. Use it in a widget: `AppLocalizations.of(context)!.yourKey`.

**Both modules share these same four files rather than having one `.arb` set per
module** — a real elder-facing sentence and an ASHA-dashboard label are both just string
resources, and one shared file per locale is what `flutter gen-l10n` expects. To avoid
merge conflicts, prefix your keys by module when you start migrating real strings
(`ashaTodaysSessions`, `patientWelcomeGreeting`, `caregiverDashboardTitle`, ...) instead of
generic names like `title` or `greeting` that both of you would reach for at once.

## A real limitation, not a bug: Flutter's own widget strings

Flutter ships built-in translations for `Text`/`Cancel`/`OK`-style framework strings
(button labels, date-picker text, tooltips) via `GlobalMaterialLocalizations` and
`GlobalCupertinoLocalizations` — but only for a fixed, curated list of languages, and
**Assamese, Bodo, and Manipuri are not on it.** That's a real limitation of Flutter
itself, not something this scaffold works around. In practice:

- Every string that comes from *our* `AppLocalizations` (the whole point of this setup)
  resolves correctly for all four locales — verified in `test/localization_test.dart`.
- Any string that comes from Flutter's own widget chrome (e.g. a default `AlertDialog`'s
  "OK"/"CANCEL", or `showDatePicker`'s month names) will print a one-time debug warning
  and fall back to its own default rendering when the app locale is `as`, `brx`, or `mni`,
  since no framework translation exists for those three. This is a Flutter-wide gap, not
  something fixable from this app's code.
- This is exactly why `AppLocalizations.delegate.load(locale)` is tested directly in
  `test/localization_test.dart` instead of through a full `MaterialApp` — pumping a real
  `MaterialApp` at `as`/`brx`/`mni` makes Flutter's own locale-support check throw inside
  `flutter test` (it only warns in a normal run), which would make the test fail on a
  Flutter-framework gap that has nothing to do with whether our own strings work.

## On the `as`/`brx`/`mni` translations already in here

`appTitle`'s value is "Smriti" itself (the Sanskrit word for "memory," which is also the
app's name) written in each language's script — Assamese and Manipuri both traditionally
use Bengali-based script (Manipuri's current official script is Meitei Mayek, adopted in
2021; this scaffold uses the Bengali-script rendering as a safer placeholder since we
don't have a verified Meitei Mayek transliteration), and Bodo uses Devanagari. These are
**placeholder transliterations for proving the pipeline renders a real non-Latin script
per locale — not reviewed translations.** Have a native speaker check every string before
any of this ships, especially for Bodo and Manipuri, which are the two languages the team
has the least in-house fluency in.
