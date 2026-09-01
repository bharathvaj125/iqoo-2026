# Bundled fonts

Per the design system (docs/FEATURES.md / the design brief): **Poppins** for headings and
buttons, **Noto Sans** for body text, with **Noto Sans Bengali** for Assamese and
**Noto Sans Meetei Mayek** for Manipuri script — required for those scripts to render
correctly at all, not a stylistic choice.

**Noto Color Emoji** is bundled too, for a different reason: web runs on CanvasKit, which
paints the whole app to one canvas via Skia's own font manager and can't reach an
OS-installed emoji font by name (naming "Segoe UI Emoji" etc. in `fontFamilyFallback` is a
no-op under CanvasKit, unlike in a real browser's HTML text). Without a bundled emoji font,
the Patient module's emoji — profile avatars, Picture Recall's items, mood faces — render
as a generic missing-glyph placeholder instead. This is the real ~25MB colour font, not a
monochrome stand-in: confirmed live that this engine's CanvasKit build actually renders
COLR colour glyphs, and the design system calls for real pictures here, not icons, so the
size cost against this app's otherwise offline-first design is accepted deliberately.

Downloaded as static TTF files (Regular/SemiBold/Bold, or Regular/Bold where a family has
no SemiBold) directly from Google Fonts and bundled as local assets — deliberately not
using the `google_fonts` package's default behavior of fetching fonts over the network at
runtime, to stay consistent with this app's offline-first design.

All five families are published by Google under the
[SIL Open Font License 1.1](https://openfontlicense.org/) — free to bundle, modify, and
redistribute, including in a compiled app, with no attribution requirement beyond keeping
the license notice available somewhere in the distribution (this file serves that purpose).
