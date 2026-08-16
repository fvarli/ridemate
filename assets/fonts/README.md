# Bundled fonts

Both families are bundled locally and **must never** be replaced by a runtime font
fetch (`google_fonts`). RideMate is a trust-first product: runtime font fetching
fails offline, leaks a request per install, and delays first paint.

The design source assigns them distinct, non-interchangeable roles:

| Family | Role |
|---|---|
| **Manrope** | All prose and UI text |
| **IBM Plex Mono** | All *data* — prices, trust scores, percentages, times, plate numbers, counts, distances |

## Provenance

### Manrope — 400 / 500 / 600 / 700 / 800

Source: `https://github.com/google/fonts/raw/main/ofl/manrope/Manrope[wght].ttf`
(variable font, `wght` axis 200–800).

Google Fonts no longer ships static instances, so the five weights here were generated
from that variable font with `fontTools.varLib.instancer` at the axis positions matching
Manrope's own named instances (400 Regular, 500 Medium, 600 SemiBold, 700 Bold,
800 ExtraBold), with `updateFontNames=True`.

To regenerate:

```python
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

for wght, name in {400: "Regular", 500: "Medium", 600: "SemiBold",
                   700: "Bold", 800: "ExtraBold"}.items():
    inst = instancer.instantiateVariableFont(
        TTFont("Manrope[wght].ttf"), {"wght": wght}, updateFontNames=True,
    )
    inst.save(f"Manrope-{name}.ttf")
```

Manrope is licensed OFL 1.1 and declares **no** Reserved Font Name, so instancing and
retaining the family name is permitted. See `OFL-Manrope.txt`.

Static instances are preferred over bundling the variable font because they let plain
`fontWeight` work everywhere, including in Material widgets and any `copyWith`, without
requiring `fontVariations` at every call site.

### IBM Plex Mono — 400 / 500 / 600

Source: the system package `fonts-ibm-plex` 6.1.1 (`/usr/share/fonts/truetype/ibm-plex/`),
which repackages the official IBM release. Upstream: `https://github.com/IBM/plex`.

Licensed OFL 1.1 with Reserved Font Name "Plex". The files are bundled **unmodified**,
so the reserved name is retained legitimately. See `OFL-IBMPlexMono.txt`.

## Glyph coverage — verified

Turkish is the source product language, so coverage was checked explicitly:

- `İ ı Ş ş Ğ ğ Ç ç Ö ö Ü ü` — **present in every bundled weight of both families.**
- `₺ → · • %` — present.
- **`★` (U+2605) is ABSENT from both families.**

The design uses `★` as a text glyph in every rating badge and as a literal `★★★★★` run in
the Reviews summary. Rendering it as text would fall through to a platform fallback font
(inconsistent between Android and iOS) or to tofu.

**Therefore stars are never rendered as text.** They use the approved `star` artwork from
the design source via `RmIcon`, which also makes them themeable and consistent. See the
star entry in `docs/design-system.md`.
