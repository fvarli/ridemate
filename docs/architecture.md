# RideMate — Architecture

> **Status:** Phase 2 complete — Onboarding, Verification and Home.
> Search, Messages, Profile and Create route remain placeholders.

## Product framing

RideMate is trust-first community ride sharing — **not** taxi/ride-hailing. People
already travelling in similar directions discover each other, share the journey, and
may share legitimate journey costs. Trust and safety are first-class product concepts:
identity verification, reputation, route matching, safety preferences, reporting and
blocking, trip sharing, and SOS.

All values visible in the design reference (amounts, Trust Scores, names, routes) are
**mock data**. No backend or business rule is inferred from them.

## Current structure

```
lib/
├── main.dart                       # ProviderScope + RideMateApp; synchronous
├── app/
│   ├── ride_mate_app.dart          # MaterialApp.router, themes, l10n, text-scale cap
│   ├── app_shell.dart              # StatefulShellRoute scaffold + placeholders
│   ├── startup_screen.dart         # neutral launch surface while state resolves
│   ├── providers/                  # theme mode, locale
│   └── router/                     # app_router.dart (Provider<GoRouter>), app_routes.dart
├── core/
│   ├── a11y/                       # RmA11y constants, RmTapTarget
│   ├── format/                     # RmFormatters, RmTextConventions
│   ├── icons/rm_icons.dart         # 25-icon registry
│   ├── theme/
│   │   ├── rm_theme.dart           # light + dark ThemeData
│   │   └── tokens/                 # colors, shadows, typography, spacing, radius,
│   │                               # sizing, motion
│   └── widgets/                    # the Rm* library
├── features/
│   ├── gallery/                    # debug-only design-system catalogue
│   ├── onboarding/                 # data + application + presentation
│   ├── verification/               # domain + application + presentation
│   └── home/                       # domain + application + presentation
└── l10n/                           # ARBs + committed generated localizations
```

Each feature has **only the layers it earns**: onboarding needs persistence so it has
`data/`; verification and home carry domain models; none has a layer it does not use.
No empty folders are scaffolded ahead of need.

## Decisions

| Concern | Decision | Rationale |
|---|---|---|
| Navigation | `go_router` 17, `StatefulShellRoute.indexedStack` | Exactly the bottom-nav-with-preserved-branch-state pattern the design needs. |
| State + DI | `flutter_riverpod` 3, **no codegen** | Provider overrides are the test seam. A second DI container would be ceremony. `rps_duel` carries codegen deps with zero usage — not repeated here. |
| Immutable models | Hand-written `@immutable final class` | Dart 3.11 covers the shapes. `freezed` waits for a real JSON contract. |
| Localization | `flutter_localizations` + `intl` + `gen-l10n` | In-SDK. Turkish is the template locale; see below. |
| Theming | `ThemeData` + two `ThemeExtension`s | See below. |
| Icons | Vendored SVG + `flutter_svg`, behind `RmIcon` | 1:1 with the approved artwork. |
| Persistence | `shared_preferences`, behind a feature-owned repository | Only the onboarding flag. Device-local UI state, not a backend service. |
| Networking | **None** | No backend exists. Nothing is built to look complete. |

### Only two ThemeExtensions

`RmColors` and `RmShadows` vary by brightness, so they are `ThemeExtension`s read via
`context.rmColors` / `context.rmShadows`.

`RmTypography`, `RmSpacing`, `RmRadius`, `RmSizing` and `RmMotion` do **not** vary by
brightness, so they are `abstract final class` constants: `const`-constructible, usable
without a `BuildContext`, and testable without a `WidgetTester`.

`RmTypography` is deliberately **colourless** — colour comes from `RmColors` at the call
site. This removes the class of bugs where a text style carries the wrong brightness's
colour.

**Deliberate deviation from the sibling Quietly project**, which uses a global mutable
palette (`AppColors.activate(brightness)`). That breaks when two brightnesses render in
one frame — which RideMate's Home screen does, floating a light sheet over a dark map —
and makes widget tests order-dependent. A regression test covers exactly that scenario.

Both extensions interpolate every field, so RideMate surfaces stay in step with
Material's own animated `ColorScheme` during a theme change.

### Riverpod boundary

`ProviderScope` is the outermost widget; `main()` is synchronous, so nothing blocks the
first frame. A neutral launch surface (`StartupScreen`) covers the moment the stored
onboarding flag is read, so neither the intro nor Home can flash before it resolves.

Providers: `themeModeProvider`, `localeProvider`, `routerProvider`,
`onboardingRepositoryProvider`, `onboardingControllerProvider`,
`verificationControllerProvider`, `homeSnapshotProvider`.

The only persisted state is the onboarding flag. Theme and locale remain in-memory.
Verification state is in-memory and **never** persisted — showing a fake verification
level that survived a restart would be misleading in a trust product.

### Three concepts that must never be coupled

```
OnboardingState   → hasSeenOnboarding   persisted; means the intro was completed
AuthState         → DOES NOT EXIST      no accounts, no sessions, no sign-in
VerificationState → in-memory mock      identity checks, unrelated to the above
```

The stored key is namespaced and narrowly named (`ridemate.onboarding.hasSeenOnboarding`)
and a test asserts it never reads as an account, session or identity claim, so a future
auth integration cannot inherit the wrong assumption.

`Hesap oluştur` continues the new-user flow. It is **not** account creation and **not**
authentication. `Zaten üyeyim` means sign in to an existing account; since sign-in does
not exist, it shows a temporary message and deliberately neither marks the intro complete
nor navigates. Both are covered by regression tests.

**Temporary Phase 2 limitation:** there is no sign-in. `onSignInRequested` is named for
what it means, so a real auth route replaces the handler without changing the component's
semantics.

### The Trust Score is never calculated here

There is deliberately no scoring function, no weights and no policy in this codebase.
The design shows two verified steps against a score of 60 — which is not 2/5, and is
itself evidence that no step-derived formula reproduces the design. A test asserts
exactly that.

Verification advancement walks a list of clearly labelled presentation scenarios, each
carrying the score to **display**. The real Trust Score is a backend-owned,
safety-sensitive concept drawing on identity verification, account age, trip history,
cancellations, ratings, reports, fraud signals and device risk. Nothing in the client
pre-empts it.

### Maps

`RmMapCanvas` is **artwork**, not a map. It reproduces the illustrated map the design
draws as inline SVG, in the design's own coordinate space. There is no tile source, no
projection, no location and no vendor, and nothing is named as though it were a provider
contract. The real maps and location architecture remains a later, separate decision.

### Router

`app_routes.dart` pairs a name and a path per route; navigation always goes by name. The
router is a provider rather than a global so it can read state and be overridden in tests.

The one redirect gates on whether the intro presentation has been completed. It is **not**
an auth guard; a future auth guard is a separate condition and must not be folded into
this one. The `ValueNotifier` bridging state to `refreshListenable` is disposed with the
provider, and the preferences instance is created once.

The shell hosts the four destinations from the design's tab bar plus a centre action that
pushes above the shell. Branches build lazily and then stay mounted, which preserves
scroll position and in-progress input once the real screens land.

## Localization and RTL

Turkish is the **source** product language: the approved design is written in Turkish and
İstanbul is the pilot market, so `app_tr.arb` is the gen-l10n template and descriptions
are authored against the Turkish original. English ships alongside it. Generated
`AppLocalizations` files are committed so a fresh clone analyzes without running codegen.

Locale resolution prefers an exact language match, defaults to Turkish when the device
reports nothing, and otherwise falls back to English rather than a half-translated
Turkish UI.

**Layouts are RTL-safe from the first widget** — `EdgeInsetsDirectional`,
`AlignmentDirectional`, `start`/`end`, never `left`/`right`. `RmIcon` mirrors only
genuinely directional glyphs. Arabic is a declared future locale, and retrofitting RTL
across 15 screens is one of the most expensive Flutter refactors; a golden baseline and
widget tests cover RTL today, before any Arabic strings exist.

### Formatting

`RmFormatters` takes an **explicit** locale and never reads `Intl.defaultLocale`.
RideMate has an in-app language override, and ambient locale state would silently desync
from it. A formatter constructed without localizations throws rather than quietly
emitting wrong units.

## Backend boundary

A real backend, database, auth, realtime, maps infrastructure, notifications, trust
engine, matching engine and safety infrastructure will come later and may live in a
separate repository.

The client's job today is to make that integration clean, not to simulate it. UI will
read from repository interfaces under `lib/services/`, bound to in-memory
implementations, with the backend phase swapping the binding in one place. **No fake
enterprise architecture is built inside Flutter.**

## Safety-critical constraint

The design contains no armed / countdown / triggered / cancelled SOS states. SOS
behaviour is **not** invented ad hoc. Before any implementation, Phase 6 delivers a
written SOS state-machine specification covering at minimum:

```
idle → confirmation/armed → countdown → triggered → acknowledged/escalated
                                     ↘ cancelled / error
```

for review and approval.

`RmPulseRing`-style animation tokens exist in `RmMotion` as generic visual primitives
with no SOS semantics attached.

## Cost-sharing constraint

Monetary copy (`maliyet paylaşımı`, `Senin payın`, `KİŞİ BAŞI`, `₺18`) is **display-only
presentation data**. No payment infrastructure, payment buttons, wallet behaviour,
transaction state or fake payment services are implemented. `RmFormatters.money` formats
a number; nothing charges anyone.

## Testing

- `tool/check.sh` — format, `analyze --fatal-infos --fatal-warnings`, and the
  host-independent test suite. This is the gate.
- `tool/goldens.sh` — the tagged golden suite, kept separate because golden images depend
  on font rasterization and the baselines are Linux-generated.
- `test/support/pump.dart` pumps through the **real** `ThemeData`, so the theme layer is
  genuinely exercised rather than bypassed.
- Token tests pin every value to the design source, so drift cannot pass silently.

`RmSkeleton` and the pulsing status dot animate indefinitely; `pumpAndSettle` will time
out on any screen showing one. Use `pump(Duration)` there.

`test/support/fakes.dart` holds the test doubles. Production ships **no** fake
implementations.
