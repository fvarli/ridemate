# RideMate — Design System

> **Status:** Phase 1 — implemented. Token code lives in
> `lib/core/theme/tokens/`, primitives in `lib/core/widgets/`.
> Every value below is pinned by `test/core/theme/tokens_test.dart`.
>
> **Source of truth:** `docs/claude-designs/RideMate App.dc.html` — immutable.
> Never reformat, rewrite, or "clean up" that file. `support.js` is generated
> runtime scaffolding and is **not** a product reference.

## 1. What the source actually is

A single-page **screen library**, not an app: one dark canvas, 5 rows × 3 phone
mockups. Structural facts that shape the implementation:

- **No CSS classes, no ids, no custom properties.** The `<style>` block is 5 lines
  (reset + two keyframes). All 797 style declarations are inline `style="..."`.
  **There is no token layer to port — it is authored from scratch here.**
- **98 inline SVG icons**, `viewBox="0 0 24 24"`, `fill="none"`, stroke 1.8–2.4,
  round caps/joins, colored by explicit semantic stroke.
- **Maps are hand-drawn inline SVG** — base rect, road strokes, `rx` building rects,
  quadratic route path. Fully reproducible in Flutter.
- **15 screens = 12 unique + 3 dark variants** (Home, Active Trip, Safety).
- **UI copy is 100% Turkish.** Board declares `İSTANBUL · PİLOT`, `TR · ₺ TRY`,
  `i18n READY · TR/EN/DE/ES/FR/AR`.

## 2. The scale rule (most important)

Every phone viewport is exactly **276 × 598** — precisely the iPhone 14 Pro
(393 × 852) aspect ratio; the notch is 96×26 against a 125×36.67 pt Dynamic Island.

**The whole artboard is drawn at a uniform 0.702 scale.**

> **Derivation rule: design px × `393/276 = 1.4239`, then snap to the token scales below.**

Transcribing literally would yield 11 px body text and 9.5 px tab labels. The rule is
self-validating on typography: body meta `11 → 15.7 ≈ 16`, list title `13 → 18.5`,
screen title `22 → 31 ≈ 32`, status bar `13 → 18.5` (iOS ships 17).

### 2.1 Clamp table — where the scale is deliberately overridden

Scale governs *proportion*, not interactive ergonomics. These deviations are intentional:

| Element | Design | ×1.4239 | **Ship** | Reason |
|---|---|---|---|---|
| Primary CTA height | 52 | 74 | **56** | Platform norm; 74 is unusable on device |
| Secondary CTA height | 48 | 68 | **52** | " |
| Icon button | 34 | 48.4 | **48** | Lands exactly on the 48 dp minimum tap target |
| Tab bar | 72 | 102 | **64 + safe area** | Use `NavigationBar` |
| FAB | 50 | 71 | **60** | Between platform norm and design intent |

Any further deviation discovered during implementation is added to this table with its
reason. The table is the contract; silent drift is not allowed.

### 2.2 Deviations recorded during implementation

| # | Deviation | Reason |
|---|---|---|
| **D-icon-1** | `home-chip` dropped; one `home` icon serves both uses | The source draws the tab icon and the "Ev" chip with different door apertures (`h-5v-6h-6v6` vs `h-4v-6h-8v6`) — an off-centre door that reads as a slip, not intent. |
| **D-icon-2** | `badge-verified` is composed in Dart, not shipped as an asset | It is two-tone in the source, so a single `currentColor` swap would render a solid blob. |
| **D-icon-3** | `check` ships in two optical weights | The source thickens the stroke as the glyph shrinks (2.6 at 14px, 3.4 at 9px). Scaling the thin one down makes it vanish in a small badge. |
| **D-icon-4** | `star-filled` is derived, not extracted | The design renders filled stars as **U+2605, which is absent from both bundled font families**. It would fall back to a platform font or tofu. The approved `star` geometry is reused as a fill. **Never render a star as text.** |
| **D-chip-1** (R4) | Selected chips keep a 1px border | In the source a selected chip drops its border, so toggling changes its size. |
| **D-chip-2** | `RmChip` labels are `Flexible` | Found via the RTL/overflow test: the bare `Text` overflowed on long Turkish labels such as `Sadece doğrulanmış`. This was a real defect, not a gallery artifact. |
| **D-color-1** | `onInk` inverts with the theme (white in light, `#0B0E14` in dark) | Found via the dark golden: `ink` is near-white in dark, so a fixed white foreground rendered white-on-white on the selected sort chip. The source has no dark sort chip, so this had no reference. |
| **D-chrome-1** | No `RmPhoneFrame` or `RmStatusBar` | The bezel and mock status bar are design-board device chrome. A real app uses `SystemUiOverlayStyle` + `SafeArea`. |

## 3. Color tokens

Colors do **not** scale. Values are taken verbatim.

### Light

| Role | Value |
|---|---|
| primary / brand | `#2E5BFF` |
| primaryPressed | `#1E3FBF` |
| primarySoft / softBorder | `#F0F6FF` / `#DCE9FF` |
| verified / success | `#18A957` · ink `#0F8A43` · soft `#E7F7EE` |
| safety / danger | `#E5484D` · gradientEnd `#C2363B` · soft `#FDEAEA` |
| rating / warning | `#F5A524` · gradientEnd `#E8841A` · soft `#FFF6E9` · border `#F6E2B8` · ink `#C98A1B` |
| background | `#F6F8FB` |
| surface / surfaceMuted | `#FFFFFF` / `#F4F6F9` |
| border / hairline / divider | `#E7E9EF` / `#EEF0F4` / `#F0F2F6` |
| ink / sub / muted / faint / disabled | `#0F1729` / `#5B6478` / `#8A93A6` / `#9AA1B0` / `#C7CDDA` |
| map canvas / road / building | `#E3E9F0` / `#D2DAE4` / `#DCE3EC` |

### Dark — a genuine re-palette, not an inversion

| Role | Value |
|---|---|
| primary / primaryText | `#4D74FF` / `#7FA0FF` |
| primarySoft / softBorder | `#16203A` / `#24365E` |
| success / soft | `#3FD07E` / `#10301F` |
| danger | `#E5484D` (**unchanged**) · icon `#FF6B70` · gradientEnd `#B22F34` · soft `#2A1518` |
| warning | `#F5A524` (**unchanged**) |
| background | `#0B0E14` |
| surface / surface2 / sheet / tabBar | `#151A23` / `#181E29` / `#11151D` / `#0E1219` |
| border / hairline | `#232A38` / `#1C2230` |
| ink / muted / faint / disabled | `#F2F4F8` / `#9BA3B4` / `#5B6478` / `#3A4252` |
| map canvas / road / building | `#0E131C` / `#1A2130` / `#151B27` |

**Dark replaces shadows with 1px borders.** Elevation is not simply dimmed.

**Identity avatar gradients:** amber `#F5A524→#E8841A` · green `#18A957→#0F8A43` ·
purple `#9D6BFF→#6E3FE8`.

**Shadow rule:** neutral shadows use `rgba(15,23,41,α)` in light and `rgba(0,0,0,.5)`
in dark; colored shadows use the fill's own hue at α `.12–.5`.

### 3.x Implementation note

`RmColors` and `RmShadows` are `ThemeExtension`s because they vary by brightness; every
other token group is a compile-time constant. See `docs/architecture.md`.

Dark values with **no reference in the source** (the design only provides dark variants
for Home, Active Trip and Safety) are derived from its own light→dark surface mapping and
flagged in `rm_colors.dart`. The warning/amber family has no dark pair at all and is
fully extrapolated — it is the first thing to review with design.

## 4. Typography

Two families, with an **enforceable split** the design applies without exception:

- **Manrope** (400/500/600/700/800) — all prose and UI
- **IBM Plex Mono** (400/500/600) — **all data**: prices, scores, percentages, times,
  plate numbers, counts, distances

Encoded as the `numeric*` roles in `RmTypography` so the split cannot drift; a test
asserts every `numeric*` role is mono and every other role is Manrope.

Fonts are **vendored** into `assets/fonts/` with their OFL licenses — not `google_fonts`,
which fetches at runtime (offline failure, privacy leak, first-paint jank). Wrong for a
trust-first product.

The source uses **63 distinct size+weight pairs** with heavy half-pixel usage
(9.5/10.5/11.5/12.5/13.5/14.5/15.5), consolidated into **20 named roles**. Only 5
elements in the source declare `line-height`; the rest were defined deliberately.

Roles are **colourless** — colour comes from `RmColors` at the call site.

Letter-spacing: `+1` on mono uppercase labels, `+0.3` on uppercase section labels,
tightening to `-0.3…-0.6` as size grows.

## 5. Radius

Source uses 22 distinct values (5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,22,26,30,36,46,99).
Normalized after scaling:

| Token | Value | Applied to |
|---|---|---|
| `xs` | 8 | progress bars, micro badges |
| `sm` | 12 | small buttons, tiny chips |
| `md` | 16 | icon tiles, small cards |
| `lg` | 20 | default card, primary button |
| `xl` | 24 | large card, input field |
| `2xl` | 28 | hero / match cards |
| `3xl` | 32 | trust-ring card |
| `sheet` | 36 | bottom-sheet top corners |
| `pill` | 999 | chips, filters, toggles |
| `circle` | — | avatars, status dots |

Chat bubbles collapse one corner to a tail (`lg` with a 6 on the tail side).

## 6. Spacing

Effective scale after ×1.4239 and snapping to 4: **4 / 8 / 12 / 16 / 20 / 24 / 32 / 40**.
**Standard screen gutter: 24** (design 18).

## 7. Component inventory (Phase 1 targets)

**Buttons** — primary full-width, primary medium, ghost/text, primary small pill,
x-small, outline small, outline full-width w/ icon, destructive (SOS), icon-only
(48/40/34), FAB, stepper ±.

**Cards** — match card in **three ranked density tiers** (best / default / condensed),
trust-score card, trust-ring hero, stat tile, route-timeline, vehicle, mutual-connection,
review, rating-summary, quick-action tile, location-share message, from/to, selector tile.

**Chips/badges** — shortcut, filter (selected = solid primary), sort (selected = solid
**ink**, not primary), rating, compatibility, status, live pill, location pill,
membership, trust-level, review attribute tag, quick-reply, date divider.

**Trust visualization — three deliberate forms:** progress ring (white-on-blue while
in progress, **green when complete**), numeric stat tile, and 4-factor breakdown bars
(`Kimlik` / `Topluluk` / `Güvenilirlik` / `Aktiflik`, where a below-threshold factor
turns **amber**).

**Verified badge** — green circle overlapping the avatar's bottom-right, bordered in the
*underlying surface color* (a cut-out effect), sizes 14–22 scaling with the avatar.

> ⚠️ **Ambiguity to resolve in Phase 1:** the same green circle means **verified** (with
> check) and **online presence** (without check). Two semantics sharing one shape is a
> real trust-signal hazard in a trust-first product. Recommend differentiating.

**Route/journey timeline** — origin ring + `flex` connector + destination teardrop. Only
2 stops are demonstrated, but the connector stretches, so intermediate stops are
structurally anticipated. The ring/teardrop pair is reused across the from/to input, the
timeline, and the map pins — one consistent origin/destination vocabulary.

## 8. Missing states — must be designed as we build

The source contains **none** of: disabled button, loading/spinner, toggle-off state,
empty state, skeleton, error state, toast/snackbar, unread badge, pull-to-refresh,
pagination, **or any armed/countdown/triggered SOS state**. Exactly one hover is declared,
on one button.

These are extrapolated from the token system during implementation, not guessed at.
SOS specifically is gated behind a written spec (see `architecture.md`).

**Screens implied but absent:** login, OTP entry, document/selfie capture, request
sent/accepted/declined, driver request inbox, my-routes, conversation list, rate-your-trip,
trusted-contacts editor, QR scanner, block/report form, settings, notifications.

## 9. Turkish formatting rules (Phase 1 → `lib/core/format/`)

`₺18` symbol prefixed, no space, no decimals · **`%94` percent before the number** ·
24h zero-padded `08:25` · `18 dk` · `12.480` (dot thousands) · masked `+90 5•• ••• 42` ·
plate `34 ABC 128` · names `Selin K.` · separator ` · ` · route arrow `→` ·
relative dates only (`Yarın`, `Dün`, `2 gün önce`, `Pzt–Cum`).

**Decision D1 (locked):** decimals render **locale-correctly via `intl`** — Turkish shows
`4,9` and `6,2 km`. The mock's anglicised `4.9` / `6.2` is a design slip and is **not**
authoritative over correct locale formatting.

## 10. Accessibility & responsiveness commitments

- Minimum tap target 48 dp — the design's 34 px icon button scales to exactly 48.
- Contrast verified against WCAG AA in both themes (the board claims "AA kontrast" for
  dark; this is verified, not trusted).
- Layouts are **RTL-safe from the first widget**: `EdgeInsetsDirectional`,
  `AlignmentDirectional`, `start`/`end` — never `left`/`right`. Arabic is a declared
  target locale and retrofitting RTL across 15 screens is one of the most expensive
  Flutter refactors.
- Text scaling respected; no fixed-height containers around scalable text.
- Golden tests cover **light + dark pairs** — the only practical guard against dark-mode
  drift across 15 screens.
