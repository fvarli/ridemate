# RideMate

Trust-first community ride sharing for İstanbul.

RideMate is **not** taxi or ride-hailing. People already travelling in similar
directions discover and match with each other, share the journey, and may share
legitimate journey costs. Identity verification, reputation, safety preferences and
emergency surfaces are first-class product concepts, not add-ons.

## Status

**Phase 3 — passenger discovery.** The design system (Phase 1) is complete, and
Onboarding, Verification, Home, Search, Match Results and Route Details are
implemented — a member can go from Home to a full route offer and back. Messages,
Profile and Create route are still placeholders.

There is no backend, no authentication, no identity-verification provider, no
payments, no location and no maps vendor. Everything those screens display is
mock presentation data.

Nothing is computed from that data either: there is no matching, ranking, pricing or
Trust Score logic anywhere in the client. The search filters change no results, and
**`Kadın sürücü` in particular is presentation only, pending legal, safety and product
review for Türkiye.** `İstek gönder` shows a "coming soon" message and creates no sent
state, because nothing was sent. See
[`docs/architecture.md`](docs/architecture.md).

## Requirements

| Tool | Version |
|---|---|
| Flutter | 3.41.1 (stable) |
| Dart | 3.11.0 |
| Android SDK | 36.x, JDK 21 |
| Xcode | required for iOS builds (not available on the current dev machine) |

Platforms: **Android + iOS only**. `linux/`, `macos/`, `windows/` and `web/` are
intentionally not generated.

## Setup

```bash
flutter pub get
```

## Quality gates

All gates run from one reproducible entry point:

```bash
./tool/check.sh
```

which runs, and requires a clean result from:

```bash
dart format --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test
```

Analyzer infos are fatal on purpose — a lint that is only a suggestion is a lint that
accumulates.

## Running

```bash
flutter run -d <android-device-id>
```

The design-system gallery is available in debug builds at `/gallery`.

An Android emulator or physical device must be started first (`flutter devices`).
iOS requires macOS with Xcode.

## Documentation

| Document | Contents |
|---|---|
| [`docs/architecture.md`](docs/architecture.md) | Structure, technical decisions and their rationale, backend boundary, safety constraints |
| [`docs/design-system.md`](docs/design-system.md) | Token derivation from the design source, the 1.4239 scale rule, color/type/spacing inventory, Turkish formatting rules |
| [`docs/release/RELEASE_IDENTITY.md`](docs/release/RELEASE_IDENTITY.md) | Permanent application identifiers and store identity |
| `docs/claude-designs/` | **Immutable** design reference — never edit or reformat |

## Design reference

`docs/claude-designs/RideMate App.dc.html` is the authoritative visual reference:
15 screens (12 unique + 3 dark-mode variants). It is treated as read-only.

All values visible in it — amounts, Trust Scores, names, routes — are **mock data**.
No backend or business rule is inferred from them.
