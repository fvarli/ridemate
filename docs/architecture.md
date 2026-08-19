# RideMate — Architecture

> **Status:** Phase 5 complete — Onboarding, Verification, Home, Search, Match Results,
> Route Details, Create Route and Chat. Active Trip is built but reachable only in debug
> builds. Messages and Profile remain placeholders.

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
│   ├── places/                     # Place + the İstanbul fixtures (shared)
│   ├── theme/
│   │   ├── rm_theme.dart           # light + dark ThemeData
│   │   └── tokens/                 # colors, shadows, typography, spacing, radius,
│   │                               # sizing, motion
│   └── widgets/                    # the Rm* library
├── features/
│   ├── gallery/                    # debug-only design-system catalogue
│   ├── onboarding/                 # data + application + presentation
│   ├── verification/               # domain + application + presentation
│   ├── home/                       # domain + application + presentation
│   ├── discovery/                  # domain + application + presentation
│   ├── create_route/               # domain + application + presentation
│   ├── chat/                       # domain + presentation
│   └── trip/                       # domain + application + presentation
└── l10n/                           # ARBs + committed generated localizations
```

`discovery/` is one slice rather than three features: `RouteOffer` feeds both the match
card and the details screen, and splitting them would force a cross-feature domain
import for no gain.

**Features never import each other.** When Create Route needed the same İstanbul places
and the same picker sheet as Search, the shared vocabulary moved to `core/places/` and
`core/widgets/rm_place_picker_sheet.dart` rather than the driver-side feature reaching
into the passenger-side one. Same rule as the design system — promote on the second
concrete consumer, never in anticipation of one — and a test asserts no file under
`create_route/` ever mentions `features/discovery`.

`core/` is therefore two things: the design system, and shared product vocabulary that
belongs to no single feature (`format/`, `places/`).

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

### Matching, ranking and cost sharing are never computed here

The same rule as the Trust Score, applied to discovery. There is no
`calculateCompatibility`, `calculateFare` or `rankMatches`, and no comparator anywhere.
`RouteOffer` carries every figure the UI shows — compatibility, cost share, trust score,
approval rate — and the widgets render what they are handed.

Sorting is the case worth spelling out. A sort chip that visibly does nothing reads as
broken, but sorting "most compatible" in code would mean the client had authored the
ranking rule for a matching engine that does not exist and will be backend-owned. So
`MockRouteOffers.orderBySort` **declares** an order per option and `orderedFor` is a
lookup, not a sort. Tests assert it echoes the declared list verbatim.

The search filters change no results at all. Filtering even a mock list would define how
RideMate applies these preferences, which is a backend, legal and product decision.

**`Kadın sürücü` needs legal, safety and product review for Türkiye before it is ever
connected to a matching engine.** Gender-based matching in transport is regulated. The
chip renders and toggles as designed and is flagged in code as
`kFilterNeedingPolicyReview`; a test asserts in particular that it filters and reorders
nothing.

### Presence is not verification

```
VerificationState → identity has been checked      RmVerification
PresenceState     → this member is online now      RmPresence
```

The design draws both as a green circle, distinguished only by a check glyph — one signal
carrying two meanings, which is a real hazard in a trust product. The rendering matches
the design exactly; the API keeps the two as **distinct types that cannot be passed for
one another**, and `RmAvatar` refuses to stack them.

Chat's header is the design's own proof that they are separate: it shows a presence dot on
the avatar **and** a verified check beside the name, at once. So the avatar takes presence
only and the check is a standalone `RmVerifiedBadge` — which is also why that badge is
public.

Neither the dot nor the badge announces itself. The correct announcement differs by
screen, so the screen composes it: Chat's header already shows a visible `Çevrimiçi` line,
so saying it again would be saying it twice, while Active Trip's driver row has no such
text and must carry the meaning in its label.

**Both are mock presentation state.** There is no presence service, and `Çevrimiçi` is a
fixture exactly like `★ 4.9`.

### Nothing on Active Trip is live

No trip session, location, GPS, permission, map vendor, realtime transport or presence
service. The car's position, the route progress, the ETA, the distance and the "live"
badge are figures from the comp, displayed unchanged.

So there is no `calculateEta`, `calculateRemainingDistance`, `calculateProgress`,
`updateVehiclePosition`, `derivePresence` or `trackingTimer`, no `TripService`,
`TrackingService`, `LocationService`, `RealtimeService` or `PresenceService`, and no
`Notifier` — the snapshot is a plain `Provider` returning a constant, because mutable trip
state is the first brick of a lifecycle that does not exist. **`travelledFraction` is never
animated and the vehicle never moves**, since a progress bar creeping over a fixture is a
route-progress calculation wearing a different hat. A test scans for every name above.

Two map fixtures are declared independently: the travelled fraction, measured once against
the chosen route point list, and the vehicle's design coordinate, which the comp puts
slightly *off* the polyline. Neither is derived from the other.

**The screen is registered only under `kDebugMode` and linked from nowhere.** Reaching an
active trip honestly needs a request, an acceptance and a departure, and fabricating
`acceptedTrip` or `currentRide` to unlock a screen is the kind of lie earlier phases
refused. It also keeps two things away from real members: an SOS control with no emergency
behaviour, and a footer claiming their live location is shared with two emergency contacts
when nothing is shared with anyone. That copy is presentation only — no location, no
contact, no background tracking, no emergency state — and a test asserts it never appears
on a release-reachable surface.

### Chat sends nothing

No backend, socket, push, delivery, read state, typing indicator, unread count or retry
queue — and none of them stubbed. `ChatEntry` carries what the design draws and nothing
added on a future backend's behalf: no `serverId`, `deliveryStatus`, `deliveredAt`,
`readAt`, `retryCount`, `remoteUserId`, `socketSequence` or `syncState`. The design shows
no timestamps, so none are manufactured, and there is no `groupByDay()` helper — it would
have to invent the very timestamps the design left out.

Send shows a message saying plainly that nothing was sent, then appends no bubble, creates
no entry, clears nothing and navigates nowhere. Leaving the typed text in place is part of
that: clearing it is what "sent" looks like. Appending a bubble was considered and
rejected — even one marked "not sent" introduces a message entity, a lifecycle and a
failed state, which is the messaging domain this phase must not build.

Opening a conversation creates no request, match, booking, accepted ride or active trip.
Messaging a driver about a route is not agreeing to travel with them.

### Maps

`RmMapCanvas` is **artwork**, not a map. It reproduces the illustrated map the design
draws as inline SVG, in the design's own coordinate space. There is no tile source, no
projection, no location and no vendor, and nothing is named as though it were a provider
contract. The real maps and location architecture remains a later, separate decision.

`RmMapProjection` maps artboard coordinates onto the widget box so overlays land on the
artwork. It is a **drawing transform and nothing else** — no latitude, no longitude, no
camera, no zoom, no tiles, no vendor. Wanting `latLngToScreen` there means wanting the real
maps architecture, which does not start in that file.

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

`/matches` and `/routes/:routeId` are **top-level** routes rather than children of the
Search branch: the design draws no tab bar on either, so they must render above the
shell. Route Details is keyed by id because Home reaches the same screen — and, later,
saved routes will too.

Back behaviour is asserted, not assumed:

| From | Back goes to | Mechanism |
|---|---|---|
| Route Details | Match Results | `pop` |
| Match Results | Search, draft intact | `pop` — the shell stayed mounted underneath |
| any secondary tab | **Home**, then exits | `PopScope` in `AppShell` |

That last row was a real gap: before it, a system back on any tab left the app.

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

This also constrains **copy**. Chat's approved safety banner tells the member to pay only
inside the app, which only makes sense if in-app payment exists. It does not, and Chat is
release-reachable, so the shipped wording keeps the banner's safety purpose without
claiming the capability (`D-chat-3`). The general rule it follows: deviate from the
approved design for truthfulness or safety, never for implementation convenience.

### The driver never sets the amount

Create Route displays a suggested per-person share captioned `Önerilen · maliyet
paylaşımı`, and it is **read-only**: no input, no stepper, no chevron, no tap target, and
a semantics node marked read-only rather than as a button.

That is a boundary, not an unfinished control. Making driver-set cost sharing editable
may materially affect how RideMate is characterized for regulatory purposes, so it
requires legal and product review before implementation rather than a decision taken in
the client layer. `kSuggestedCostSharePerPerson` carries that requirement in its doc
comment so nobody makes it editable in a later phase without meeting it.

The amount is also not derived from distance, duration, seats, recurrence, route or
vehicle, and **no total is displayed anywhere**: `seats × costShare` would be both a
formula this layer may not author and a driver-earnings claim the product does not make.
A test increments the seats and asserts the figure does not move.

Vocabulary inside `create_route/` stays on the design's own words — `KİŞİ BAŞI`,
`maliyet paylaşımı` — and never becomes fare, price, earnings, income, payout or revenue.

### Ride rules are published rules, not eligibility

A driver's `RideRuleId` and a passenger's `SearchFilterId` carry some of the same words
(`Sigara yok`) from opposite sides of the same conversation. They stay separate types in
separate features; reconciling them is a backend concern.

Neither drives any behaviour. `kRuleNeedingPolicyReview` marks `Evcil hayvan yok` the way
`kFilterNeedingPolicyReview` marks `Kadın sürücü`: it is a policy-sensitive preference,
the client enforces no eligibility from it, and connecting it to real matching requires
legal, accessibility and product review first. Those markers record a review requirement
and assert nothing about how any particular law applies.

## Actions that do not exist yet say so

`İstek gönder` on Route Details shows a localized *"Yolculuk isteği özelliği yakında
eklenecek."* and creates **no** sent state: it does not flip the button, mutate the offer
or start a request lifecycle. Nothing was sent anywhere, and claiming otherwise is the
wrong thing to encode in a trust product. When a backend exists the flow becomes
request → server acknowledgement → pending → accepted/declined, and only then may the UI
claim anything was sent.

Phase 5 added three more, each naming what did not happen rather than promising a feature:
sending a message (`Mesaj gönderilmedi.`), sharing a trip (`Hiçbir şey paylaşılmadı.`) and
SOS (`Kimseye bildirim gönderilmedi.`). The SOS wording is deliberately narrow: no
countdown, no confirmation, no armed or triggered state, no call, no contact notification,
no location sharing and **no emergency number** — none appears in the approved design, and
hard-coding one country's would invent safety guidance for every market. The real SOS state
machine stays gated behind the written specification above.

`Rotayı yayınla` on Create Route is the same pattern with sharper copy, because
*yayınla* implies other members can now see the journey. The message states that the
route has **not** been published rather than merely that publishing is coming, and the
action creates no route, marks nothing published, does not mutate or clear the draft, and
does not navigate. It is also deliberately **not** gated on draft validity: the source
contains no disabled button anywhere, and inventing validation would author a publishing
rule that does not exist.

The Create Route draft lives in an app-scoped provider so backing out by accident does
not discard the driver's edits, and in memory only — nothing is written to
`SharedPreferences` or any local store, so a new process starts from the designed
defaults. When publishing is real, drafts become persisted entities and that scope is
revisited.

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

Any test that asserts something about **width** must call `loadRideMateFonts` first.
Without it every glyph rasterizes as a square em box, much wider than Manrope, so the
test measures the placeholder font instead of the product — failing where the app is
fine and passing where it is not. Screens are checked at **360dp as well as 393dp**, in
both locales, RTL, and at the maximum supported text scale.

`test/support/fakes.dart` holds the test doubles. Production ships **no** fake
implementations.
