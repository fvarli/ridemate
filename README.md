# RideMate

Trust-first community ride sharing for İstanbul.

RideMate is **not** taxi or ride-hailing. People already travelling in similar
directions discover and match with each other, share the journey, and may share
legitimate journey costs. Identity verification, reputation, safety preferences and
emergency surfaces are first-class product concepts, not add-ons.

## Status

**Phase 7 — the approved screens are complete and the repository has a production floor.**
The design system (Phase 1) is done, and Onboarding, Verification, Home, Search, Match
Results, Route Details, Create route, Chat, Profile and Reviews are implemented. Active
Trip and the Safety Center are built and tested but reachable **only in debug builds** —
see below. Messages is the one remaining placeholder, because the design has no
conversation list.

Phase 7 added no product behaviour. It added CI, fail-closed release signing, application
error handling, persisted preferences and landscape coverage — the things that have to be
right before a backend is connected in the next phase. See
[`docs/architecture.md`](docs/architecture.md) under *Production floor*.

There is no backend, no authentication, no identity-verification provider, no
payments, no location and no maps vendor. Everything those screens display is
mock presentation data.

Nothing is computed from that data either: there is no matching, ranking, pricing or
Trust Score logic anywhere in the client. The search filters change no results, and
**`Kadın sürücü` and `Evcil hayvan yok` are presentation only, pending legal, safety and
product review.** The Create route cost share is read-only for the same reason.
`İstek gönder` and `Rotayı yayınla` show honest messages and create no sent or published
state, because nothing was sent or published. See
[`docs/architecture.md`](docs/architecture.md).

Chat sends nothing. There is no messaging backend, no delivery or read state and no
typing indicator, so the send button says plainly that the message was not sent and adds
nothing to the conversation. Its safety banner also differs from the comp on purpose: the
approved wording tells you to pay inside the app, and there is no payment feature, so it
keeps the safety advice without the false claim.

Profile shows a Trust Score, a four-factor breakdown of it and a reputation summary.
**None of it is calculated.** There is no scoring service, so every figure is copied from
the design — including the ones that nearly reconcile: the four factors mean 91.5 against
a displayed 92, and Reviews' histogram, its two visible cards and its headline rating all
come to 4.9 by coincidence. Tests pin each of those as a coincidence, because turning one
into a formula would be authoring the scoring policy rather than fixing a rounding error.

**Active Trip and the Safety Center are debug-only.** Reaching a trip in progress
honestly needs a request, an acceptance and a departure, none of which exist — and rather
than fake that lifecycle to unlock a screen, the route is left out of release builds
entirely. It carries an SOS control with no emergency behaviour and a footer saying your
live location is shared with two emergency contacts, which is not true of anything.

The Safety Center is withheld for the same reason and more sharply. Its SOS card promises
that pressing it sends your location and journey to your emergency contacts and to our
team; a tile offers to call 112; a row says two trusted contacts have been added. There
is no backend, no telephony, no location and no contact store, so none of that is true.
Softening the approved safety copy would leave a surface that still reads as real, so the
copy ships as approved and the route stays out of release builds instead. The design
draws **one** of the eleven states an SOS control would need, and the two most likely
real outcomes — permission denied, no contacts added — are among the ten it does not.
[`docs/architecture.md`](docs/architecture.md) records the state model and the five
things that must exist before the screen can be reached at all.

Every screen delivers the **approved design surface**, not a production-complete
feature. Create route still has no departure date or time control, so a one-off journey
cannot say when it leaves; the Safety Center's three tool rows point at a trusted-contacts
editor, a QR scanner and a block/report form that were never drawn. All of it is listed in
[`docs/design-system.md`](docs/design-system.md) §8. With the designed screens now built,
that list is the input to the dedicated product-gaps phase.

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

CI runs that same script rather than a copy of its steps, so the two cannot drift.
Goldens stay out of CI deliberately — they are host-dependent, and the workflow header
records both the reason and what would change it.

**Expected toolchain: Flutter 3.41.1 (stable).** `pubspec.yaml` declares a floor, since a
pubspec cannot pin the SDK itself; the exact version is pinned in
`.github/workflows/check.yml`. No version manager is used.

## Release builds

Release signing **fails closed**. There is no debug-key fallback:

```bash
flutter build apk --release          # fails unless android/key.properties exists
```

`android/key.properties` is git-ignored and must never be committed. See
[`docs/release/RELEASE_IDENTITY.md`](docs/release/RELEASE_IDENTITY.md) for how the upload
key is created. For structural checks only, an explicitly unsigned artifact:

```bash
flutter build apk --release -Pridemate.allowUnsignedRelease=true
```

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
All twelve are now implemented.

All values visible in it — amounts, Trust Scores, names, routes — are **mock data**.
No backend or business rule is inferred from them.
