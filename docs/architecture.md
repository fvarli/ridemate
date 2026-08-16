# RideMate — Architecture

> **Status:** Phase 0 (bootstrap). Everything below the "Phase 0 state" section
> is a decided plan, not yet implemented.

## Product framing

RideMate is trust-first community ride sharing — **not** taxi/ride-hailing. People
already travelling in similar directions discover each other, share the journey, and
may share legitimate journey costs. Trust and safety are first-class product concepts:
identity verification, reputation, route matching, safety preferences, reporting and
blocking, trip sharing, and SOS.

All values visible in the design reference (amounts, Trust Scores, names, routes) are
**mock data**. No backend or business rule is inferred from them.

## Phase 0 state (current)

```
lib/
├── main.dart                  # runApp(RideMateApp())
└── app/ride_mate_app.dart     # minimal MaterialApp + placeholder
test/
└── app/ride_mate_app_test.dart
tool/check.sh                  # format + analyze + test
```

No third-party dependencies. No theming, routing, localization, state management,
services or product screens — all Phase 1+.

## Target structure

```
lib/
├── main.dart
├── app/            # root widget, bootstrap guard, router
├── core/           # a11y, format, icons, theme/tokens, widgets (rm_*)
├── features/       # onboarding, verification, home, search, matches,
│                   # route_create, route_details, trip, chat,
│                   # profile, reviews, safety
├── services/       # cross-feature: session, routes, matching, trust,
│                   # chat, safety, location, map
├── state/models/
└── l10n/           # app_tr.arb (template), app_en.arb
```

Feature-first with a small shared core, matching the structure proven in
`quietly_media_saver`. Each feature gets only the layers it earns
(`presentation` / `domain` / `data`) — empty ceremonial folders are not created.

Design-system primitives use the **`Rm`** prefix (`RmButton`, `rm_button.dart`),
mirroring the `q_*` convention in Quietly. The design source itself already uses this
prefix in its `rm-pulse` / `rm-ring` keyframes.

## Decisions

| Concern | Decision | Rationale |
|---|---|---|
| Navigation | `go_router` | Declarative, deep-linkable; the onboarding → verification → home redirect guard is exactly its strength. |
| State + DI | `flutter_riverpod`, **no codegen** | Provider overrides are the test seam for mock repositories. A second DI container (`get_it`) would be pure ceremony. Quietly deliberately dropped the codegen that RPS Duel used — follow the newer decision. |
| Immutable models | Hand-written `@immutable final class` + `copyWith` | Dart 3.11 sealed classes and pattern matching cover the domain shapes. `freezed`/`json_serializable` are deferred until a real JSON contract exists. |
| Localization | `flutter_localizations` + `intl` + `gen-l10n` | In-SDK. TR default, EN second, **all layouts RTL-safe** so DE/ES/FR/AR are translation-only work later. |
| Theming | `ThemeData` + `ThemeExtension` | See deviation below. |
| Icons | Vendored SVGs + `flutter_svg`, behind `RmIcon` | The design's 98 inline SVGs are the approved artwork; an off-the-shelf icon set would be close but not exact. |
| Networking | **None yet** — abstract repositories + in-memory implementations | No backend exists. Adding an HTTP client now would be architecture theatre. The Riverpod provider is the swap point. |
| Map | `MapRenderer` interface + vector renderer | The design's maps are hand-drawn SVG, fully reproducible in Flutter, so the maps-vendor decision defers at zero visual cost. |

### Deliberate deviation: theming via `ThemeExtension`

Quietly uses `AppColors.activate(brightness)` — a global mutable static palette swapped
once per build. RideMate does **not** copy this.

Reason: it is global state. It breaks when two brightnesses render in one frame — which
RideMate's Home screen literally does (a light sheet floating over a map) — and it makes
widget tests order-dependent.

RideMate instead reads tokens from `Theme.of(context).extension<RmColors>()!`. Same
discipline (**tokens are never hard-coded as hex in widgets**), but context-scoped,
`lerp`-able across theme transitions, and safe for golden tests that render light and
dark side by side.

## Backend boundary

A real backend, database, auth, realtime, maps infrastructure, notifications, trust
engine, matching engine and safety infrastructure will come later and may live in a
separate repository.

The client's job today is to make that integration clean, not to simulate it. Concretely:
UI reads from repository interfaces in `lib/services/*`; Phase 1–7 bind those to
in-memory mock implementations; the backend phase swaps the binding in one place.

**No fake enterprise architecture is built inside Flutter.**

## Safety-critical constraint

The design contains no armed / countdown / triggered / cancelled SOS states. SOS
behavior is **not** invented ad hoc. Before any implementation, Phase 6 delivers a
written SOS state-machine specification covering at minimum:

```
idle → confirmation/armed → countdown → triggered → acknowledged/escalated
                                     ↘ cancelled / error
```

for review and approval.

## Cost-sharing constraint

Monetary copy in the design (`maliyet paylaşımı`, `Senin payın`, `KİŞİ BAŞI`, `₺18`) is
**display-only presentation data**. No payment infrastructure, payment buttons, wallet
behavior, transaction state or fake payment services are implemented.
