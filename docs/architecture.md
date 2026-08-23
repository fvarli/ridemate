# RideMate — Architecture

> **Status:** Phase 7 complete — every approved screen is built, and the repository has a
> production floor: CI, fail-closed release signing, application error handling and
> persisted preferences. Active Trip and the Safety Center are reachable only in debug
> builds. Messages remains the one placeholder, because the design has no conversation
> list.

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
│   ├── trip/                       # domain + application + presentation
│   ├── profile/                    # domain + application + presentation
│   ├── reviews/                    # domain + presentation
│   └── safety/                     # domain + application + presentation (debug-only)
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

Phase 6 kept three features apart rather than merging them into one profile slice, and
built **no shared `User` model**. Profile, Reviews and Safety each hold their own
snapshot: a single user object would invite every screen to read fields it has no source
for, and the three surfaces make genuinely different claims — verification, reputation,
and emergency capability. Where they must agree, a test enforces it instead: Profile's
`4 / 5` badge is asserted against `VerificationStepId.values.length`, and Profile does
not import the verification feature to get there.

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

`ProviderScope` is the outermost widget. `main()` is async: it resolves preferences and
opens the credential store before the first frame, then starts session restoration
**without awaiting it**. Blocking on a network round trip would stall launch for as long as
a bad connection takes, on a device that may have nothing to restore.

`StartupScreen` covers the moment either dimension is still resolving, so nothing flashes.

Providers include `themeModeProvider`, `localeProvider`, `routerProvider`,
`onboardingRepositoryProvider`, `onboardingControllerProvider`, `credentialStoreProvider`,
`rmSessionProvider`, `verificationControllerProvider`, `homeSnapshotProvider`.

`rmSessionProvider` deliberately has **no default**, unlike the others. A default would need
an HTTP client and a base URL, and the only honest values for those reach the network — so a
test that forgets to override it fails clearly instead of making a request.

Persisted state, and only this:

| What | Where | Why there |
|---|---|---|
| `hasSeenOnboarding` | `SharedPreferences` | device-local UI state |
| install marker | `SharedPreferences` | must NOT survive an uninstall — that is the point |
| refresh token + session id | platform secure storage | credentials |
| **access token** | **memory only** | 15-minute life; a cold start re-mints it from the refresh token before the first authenticated call, so persisting it would buy milliseconds and widen a device dump |
| passcodes | **nowhere, ever** | single-use, five-minute life |

Theme and locale remain in memory. Verification state is in-memory and **never** persisted —
a fake verification level surviving a restart would be misleading in a trust product.

### Three concepts that must never be coupled

```
OnboardingState   → hasSeenOnboarding   device-local flag; the intro was completed
SessionState      → unresolved / signed out / signed in   a credential the server accepts
VerificationState → in-memory fixture   identity checks; unrelated to both
```

Onboarding and session are **independent dimensions**, and the combinations are why: a member
who reinstalls has a session and no flag; one who signed out has the flag and no session.
Collapsing them into a single boolean gets both wrong. Keys are namespaced per store —
`ridemate.onboarding.`, `ridemate.prefs.`, `ridemate.install.`, `ridemate.credential.` — so
the three cannot grow into each other, and tests assert no credential key appears in
`SharedPreferences`.

Both onboarding CTAs now **mark the intro seen and enter the same phone/passcode flow**.
Marking it is not incidental: onboarding takes precedence over authentication in the router,
so a CTA that navigated to sign-in with the flag still false would be redirected straight back
and the member would tap and watch nothing happen.

They still mean different things to the member — one expects an account to exist and the other
does not — but that is not a difference the CLIENT can act on. A verified number either
belongs to an account or does not, and the server decides on one endpoint precisely so that
asking cannot reveal who is already a member. Two client journeys would have to know the
answer before asking.

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

### The Verification screen left the release build in Phase 9

Once account identity became real, three of its statements became false claims about a
member's actual account: its email step reads `Doğrulandı` from a fixture, its progression is
a scripted demo no backend drives, and its Trust Score has no engine behind it. Harmless while
every account was imaginary; not harmless now.

Its route is therefore registered under `if (kDebugMode)`, beside Active Trip and Safety, and
a test asserts the guard is there. **The screen, its fixtures, its tests and its 34-baseline
goldens all remain** as the approved design reference — only the release entry point is gone,
and its former entry point now leads to sign-in.

It returns to release when **all** of these hold, and a test asserts these conditions stay
recorded beside the guard:

1. verification presentation state is served by the backend;
2. the Trust Score is a value the server computes and owns;
3. at least one non-phone step has a real submission path;
4. every displayed status is traceable to backend state;
5. it migrates as one coherent change, never as a hybrid of real and fixture data.

Phone verification is the one part that became real, and it is a column
(`accounts.phone_verified_at`) rather than a table — an account exists only after a passcode
is verified, so a verifications table would hold one row per account, of one kind, in one
state. Email, identity, selfie and licence verification exist on neither side.

**Phase 6 added the breakdown, which is where a policy could have slipped in.** Profile
draws four factors — 100 / 90 / 94 / 82 — under a score of 92. Their mean is 91.5: close
enough that turning it into a formula looks like fixing a rounding error rather than
authoring a scoring rule. A test asserts the two stay unequal. Each factor's colour is a
**declared field**, never derived from its value, because 82 amber beside 90 blue would
otherwise define a cut-off nobody has decided. And the line `100'e ulaşmak için 1
yolculuk daha` asserts eight points per journey — it ships as one opaque ARB message with
no placeholder so it cannot be parameterised into a rate, with a test on the ARB itself
because no test of the code would catch it.

**Reputation is the same rule.** Reviews' histogram weighted out is 4.90, its two visible
cards average 4.9, and both equal the headline rating. All three are independent declared
fixtures; the tests assert the agreements are coincidences rather than sources. There is
no `aggregateRatings`, no `ratingFromDistribution` and no bucket-count derivation.

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

Its SOS button now opens the Safety Center, which is withheld for the same reason and
more sharply, so the two make one flow to review. The test that pins the route behind
`kDebugMode` was generalised in Phase 6 to check **every** guarded route rather than this
one, so a third cannot be added in a way that weakens the check.

### Nothing on the Safety Center is real either

No emergency dispatch, telephony, trusted-contact store, location sharing, QR
verification, moderation pipeline or notification channel — and none of them stubbed. The
snapshot holds exactly one field, a display count, which is itself untrue.

So there is no `EmergencyService`, `DispatchService`, `ContactsService`, `QrService`,
`BlockService`, `ReportService` or `ModerationService`, no `sosTriggered`,
`emergencyActive`, `blockedUsers` or `reportSubmitted` field, no `tel:` URI,
`url_launcher`, `MethodChannel` or permission request anywhere, and no `Notifier` — the
snapshot is a plain `Provider` returning a constant. A test scans for every name above.

See the safety-critical constraint below for the SOS state model and the five things that
must exist before the screen can be reached at all.

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

The redirect answers two independent questions, in this order:

1. **either dimension unresolved** → `StartupScreen`. The session resolves over the network,
   so it is the slower of the two and the one that would otherwise flash a sign-in form at
   somebody already signed in.
2. **intro unseen** → `/onboarding`. It wins whatever the credential says: someone who has
   never seen the intro should not meet a sign-in form first.
3. **signed in** → the shell, with `/startup`, `/onboarding` and the auth routes as dead
   ends. This is what stops stale navigation history returning a valid session to a sign-in
   screen.
4. **signed out** → `/auth`, unless already on an auth route. That exception is what stops
   `/auth/passcode` being redirected back to `/auth` while the member is typing.

A test walks all six combinations of the two dimensions and asserts each settles rather than
looping. There is **no verification gate and no profile-completion gate**; a test scans the
redirect body and fails if either word appears in it.

`refreshListenable` merges the onboarding `ValueNotifier` with the session's own
`ValueListenable`, so neither dimension is derived from the other. The notifier is disposed
with the provider and the preferences instance is created once.

**Session-ended notice.** A member returned to sign-in because their session stopped working
is told so, once. It is transient and in memory — a stored "your session ended" would
reappear after an unrelated restart weeks later with no session to explain it — and it is
consumed on read, because the redirect re-evaluates on every navigation. It never appears on a
first launch (nothing was refreshed), after an explicit sign-out (the app would be explaining
an event the member caused), or after a reinstall purge. A suspended account gets its own
distinct copy, because "sign in again" is precisely the advice that cannot work for one.

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

## Production floor

Phase 7 added no product behaviour. It made the repository safe to connect a backend to.

### Release signing fails closed

The Flutter template signs release builds with the shared debug key. That line is gone and
there is no fallback: a release signing config exists only when `android/key.properties`
does, and a release task requested without it stops at configuration time with a message
naming the file and the keys. An unsigned artifact is still obtainable for structural
checks, but only behind an explicitly named property, so "the release build succeeded" can
never quietly mean "unsigned". See `docs/release/RELEASE_IDENTITY.md`;
`test/app/android_release_config_test.dart` asserts the debug config cannot return.

### Errors are observed, never suppressed

`installRmErrorHandlers` installs two hooks that are disjoint by construction:
`FlutterError.onError` for framework errors and `PlatformDispatcher.instance.onError` for
uncaught asynchronous ones. **`runZonedGuarded` is deliberately not used** — it would catch
the same async errors the platform hook already delivers and report each one twice.

`PlatformDispatcher.instance.onError` **returns `false`**. That means "not handled": the
error still reaches the default handler and platform behaviour is unchanged. Returning
`true` would silence a crash while nothing records it, which is worse than the crash.

`reportError` is one function, not an interface. There is exactly one implementation and a
hierarchy for it would be the ceremony this document forbids elsewhere; a crash reporter
attaches inside it, and nothing else in the app moves. No vendor ships in this phase.

The router's error surface shows a member a localized sentence and one recovery action
that genuinely resolves. **No exception text, stack frame, attempted route or error code
reaches the screen** — those go to the report. The framework's red error box is replaced
only under `kReleaseMode`, because in debug and under test that box is how a broken build
announces itself.

### Preferences are persisted, and cannot lose a race

Theme mode and locale are device-local UI preferences, stored under `ridemate.prefs.*`
through their own repository. They are not onboarding state and not session state; the
three concepts stay separate, and share a platform store only because that is one store,
not one concept.

The store is resolved in `main()` and injected into the root scope, so provider `build()`
reads it synchronously. **This is why `main()` is async**, reversing the Phase 1 decision
to keep it synchronous — that decision predated there being anything to load, and became
the reason preferences reset on every restart.

The ordering is the design, not an implementation detail: because nothing arrives after
the first frame, **no late read can overwrite a newer choice**. A notifier that returned a
default and then hydrated would lose that race on a fast toggle, and guarding against it
would mean defending a hazard that need not exist. Writes are fire-and-forget with their
own error handler; a failed write is reported and the member keeps their choice. A store
that cannot be opened degrades to a session-only one, so a broken preference store cannot
stop the app from starting.

### Orientation is deliberately not locked

The approved design is a portrait phone comp. That is a reason to design for portrait and
not a reason to forbid landscape: a phone in a car mount is landscape, and members who
cannot comfortably rotate a device rely on the system honouring what they chose. Neither
platform restricts orientation and nothing calls `setPreferredOrientations`;
`test/app/orientation_test.dart` smoke-tests every screen at two landscape surfaces and
asserts the decision has not been reversed. **A screen that breaks in landscape is a
responsive defect, not an argument for a lock** — Onboarding was one, and was fixed.

### Two kinds of version decision

They are not the same thing and the repository keeps them apart:

* **Inherited from the Flutter SDK on purpose** — `minSdk`, `targetSdk`, `compileSdk`,
  `ndkVersion`. `RELEASE_IDENTITY.md` locks that; overriding would fight generated config.
* **Pinned for reproducibility** — every direct dependency, plus a committed `pubspec.lock`.
  `intl` is the deliberate exception: `flutter_localizations` pins it to an exact version,
  so `any` is what lets the SDK own it and a caret range would break `pub get` the day
  Flutter bumps that pin.

The toolchain itself cannot be pinned from a pubspec. `environment.flutter` declares a
floor, the exact version lives in `.github/workflows/check.yml`, and neither pretends to be
the other. No version manager is introduced.

### CI

`.github/workflows/check.yml` runs `tool/check.sh` rather than restating its steps, so the
script stays the single definition of green and local and CI cannot drift. A second job
builds the debug APK. **Goldens are excluded for a specific reason, not a verdict**: the
emoji font `test/support/fonts.dart` loads is best-effort, so a runner without one bakes
tofu into the Chat baselines. The revisit trigger is a pinned container image with a fixed
font set and Flutter revision.

## Backend boundary

The backend lives in a separate repository (`ridemate-backend`, Laravel + PostgreSQL). As of
Phase 9 **authentication is real**; everything else is still fixture-backed.

`lib/core/api/` is the only place that speaks HTTP. `package:http` is imported by exactly one
file and a test enforces it, so replacing the transport is a change inside that directory
rather than a search across the app. `RmFailure` carries a status, a typed `RmErrorCode` and
`request_id` — and deliberately **not** the backend's `message`, which is developer-facing
English the contract says clients must never display. Making it unavailable is a stronger
guarantee than asking nobody to reach for it.

Requests are bounded by a single timeout in `RmApiClient`. Without one, a backend that accepts
a connection and never answers leaves restoration pending forever and the launch surface up
indefinitely — the app looks broken rather than offline.

`lib/core/session/` owns the session: single-flight refresh so concurrent 401s share one
`/auth/refresh` call, retry-once after it succeeds, and fail-closed persistence — a rotated
credential that cannot be written signs the member out rather than leaving a session that
works until the process ends. `flutter_secure_storage` is confined to one implementation file
by test.

**Still fixtures, and honestly so:** Profile including Trust Score, tier and factors; Home;
Search and route offers; Create Route; Active Trip; Reviews; Safety. Email, identity, selfie
and licence verification do not exist on either side.

The base URL is **build-time configuration** — `--dart-define=RIDEMATE_API_BASE_URL` — with no
default and no production URL in the repository. An absent or unusable value fails at startup
with the exact command to run, rather than silently choosing an endpoint. Cleartext HTTP is
permitted for `10.0.2.2`, `127.0.0.1` and `localhost` **in debug builds only**, through a
network security config under `android/app/src/debug/`; release keeps Android's default and
denies it everywhere.

**No fake enterprise architecture is built inside Flutter.**

## Safety-critical constraint

**Phase 6 implements `idle` and nothing else.** The Safety Center is built, and the SOS
control on it does exactly one thing: it says that nobody was notified.

### One of eleven states is designed

| State | Approved visual | What it needs before it can exist |
|---|---|---|
| `idle` | **yes** — the red card with the halo, and Active Trip's red button | shipped |
| `pressed` | no | the source declares exactly one hover, on an unrelated button; there is no pressed state anywhere in it |
| `confirming` | no | a dialog or sheet, plus a decision on whether confirmation is even right for an emergency control |
| `countdown` | no | a duration, a cancel affordance, the cancel window, haptics or audio |
| `armed` | no | a persistent indicator that survives across screens |
| `activated` / `triggered` | no | who was contacted, over what channel, and when |
| `cancelled` | no | the path back to idle, and whether a cancelled alert is retained |
| `permission-denied` | no | **the most likely real outcome**, and entirely undesigned |
| `no-contacts` | no | the other likely one: the member never added anyone |
| `failed` / offline | no | retry, queueing, and what "failed" means for a safety alert |
| `expired` / `resolved` | no | the post-incident state, and data retention |

Writing the other ten from intuition is exactly what this section exists to prevent. **No
`SosState` enum exists in the codebase**, and a test asserts it: a one-member enum is
where the missing ten get invented.

### Capabilities that must exist first

This is not primarily a UI state machine. It crosses into telephony, background location,
push delivery and a server that receives an alert and escalates it:

1. a backend that accepts an alert, acknowledges it, and can be **observed** to have done so;
2. trusted-contact storage plus a delivery channel — push? SMS? call? — with delivery evidence;
3. location semantics: precision, duration, who can see it, and how it stops;
4. the permission model — foreground and background location, notifications — and every denial path;
5. emergency-call behaviour **per jurisdiction** (112 is EU and Turkey; English ships today and Arabic is declared);
6. cancellation semantics, and whether a cancelled alert is retained;
7. incident data retention and access.

### Release criteria for the Safety Center

The screen is registered **only under `kDebugMode`** — absent from the release route
table, not merely unlinked — and nothing in any product surface navigates to it. Tests
assert both, and assert that its untrue claims appear on no release-reachable surface.

It becomes reachable when **all five** of these exist, and not before: an approved SOS
state machine · trusted-contact semantics · location-sharing semantics · emergency-call
behaviour · the permission and failure states. Until then the honest move is to withhold
the screen rather than soften the approved safety copy, which would leave a surface that
still reads as real.

Debug-only is about the **entry point, not the code**. The screen is localized,
accessible, RTL-safe, themed, tested and captured in goldens like anything else. What is
withheld is reachability.

`RmMotion`'s ring tokens and `RmHalo` are generic visual primitives with **no SOS
semantics attached**. The halo says nothing about whether anything is happening.

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

Phase 6 added four more, and deliberately gave each its **own** sentence rather than one
shared apology. `112'yi ara` says the app cannot start phone calls **at all** — a
different failure from a call that did not connect, and the useful one for a reviewer to
read. The three tool rows name their three missing capabilities: trusted contacts, QR
verification, blocking. None of them navigates, stores anything or requests a permission,
and in particular **no block is remembered**: a member believing they are protected from
someone when nothing happened is the most dangerous state this app could hold.

The Safety Center's SOS card reuses Active Trip's string rather than restating it. One
concept, one sentence — the keys are named `sos*` rather than `activeTripSos*` for that
reason.

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

A green suite is not the same as a correct screen. Every changed golden is **looked at**
before its baseline is accepted: Phase 6's pass caught an ellipsised breakdown label, the
brand-blue glow under a red emergency card, and an SOS glyph left at its raw unscaled
size — none of which any assertion would have failed on.
