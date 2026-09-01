# Bundled fonts

Per the design system (docs/FEATURES.md / the design brief): **Poppins** for headings and
buttons, **Noto Sans** for body text, with **Noto Sans Bengali** for Assamese and
**Noto Sans Meetei Mayek** for Manipuri script — required for those scripts to render
correctly at all, not a stylistic choice.

**Noto Emoji** is bundled too, for a different reason: web runs on CanvasKit, which paints
the whole app to one canvas via Skia's own font manager and can't reach an OS-installed
emoji font by name (naming "Segoe UI Emoji" etc. in `fontFamilyFallback` is a no-op under
CanvasKit, unlike in a real browser's HTML text). Without a bundled emoji font, the Patient
module's emoji — profile avatars, Picture Recall's items, mood faces — render as a generic
missing-glyph placeholder instead. Monochrome, not the far larger colour Noto Color Emoji;
covers all but one of the ~39 codepoints this app actually uses (see core/theme.dart's
`_scriptFallbacks` doc comment) at a fraction of the size.

Downloaded as static TTF files (Regular/SemiBold/Bold, or Regular/Bold where a family has
no SemiBold) directly from Google Fonts and bundled as local assets — deliberately not
using the `google_fonts` package's default behavior of fetching fonts over the network at
runtime, to stay consistent with this app's offline-first design.

All five families are published by Google under the
[SIL Open Font License 1.1](https://openfontlicense.org/) — free to bundle, modify, and
redistribute, including in a compiled app, with no attribution requirement beyond keeping
the license notice available somewhere in the distribution (this file serves that purpose).
