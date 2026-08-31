# Bundled fonts

Per the design system (docs/FEATURES.md / the design brief): **Poppins** for headings and
buttons, **Noto Sans** for body text, with **Noto Sans Bengali** for Assamese and
**Noto Sans Meetei Mayek** for Manipuri script — required for those scripts to render
correctly at all, not a stylistic choice.

Downloaded as static TTF files (Regular/SemiBold/Bold, or Regular/Bold where a family has
no SemiBold) directly from Google Fonts and bundled as local assets — deliberately not
using the `google_fonts` package's default behavior of fetching fonts over the network at
runtime, to stay consistent with this app's offline-first design.

All four families are published by Google under the
[SIL Open Font License 1.1](https://openfontlicense.org/) — free to bundle, modify, and
redistribute, including in a compiled app, with no attribution requirement beyond keeping
the license notice available somewhere in the distribution (this file serves that purpose).
