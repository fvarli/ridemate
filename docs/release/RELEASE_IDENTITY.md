# RideMate — Release Identity

> **Status:** Locked · **Last updated:** 2026-08-16 · **Owner:** Lunexa
> Permanent and near-permanent identity decisions for RideMate's release.
> Follows the convention established in `quietly_media_saver/docs/release/RELEASE_IDENTITY.md`.

## Locked decisions

| Field | Value | Notes |
|---|---|---|
| **applicationId / namespace** (Android) | `com.lunexa.ridemate` | **Permanent** after first publish |
| **Bundle identifier** (iOS) | `com.lunexa.ridemate` | Verified in `project.pbxproj`; tests use `.RunnerTests` |
| **Publisher / developer** | **Lunexa** (umbrella) | Not "Lunexa Games" — RideMate is a service, not a game |
| **Website / contact** | `https://uselunexa.com` | |
| **Support email** | `hello@uselunexa.com` | Ecosystem-wide |
| **Privacy URL** | `https://uselunexa.com/privacy/ridemate` | + `/tr/privacy/ridemate` |
| **Initial market** | Türkiye — İstanbul pilot | Design board declares `İSTANBUL · PİLOT` |
| **Default locale** | `tr` (Turkish), with `en` as second locale | Design copy is 100% Turkish |
| **Currency** | `₺` TRY | Design board declares `TR · ₺ TRY` |
| **Versioning** | semver `versionName` + monotonic `versionCode` | Starts `0.1.0+1` (pre-release) |

## Rationale

**Namespace (`com.lunexa.ridemate`).** Adopts the flat `com.lunexa.<app>` root that
`RELEASE_IDENTITY.md` for Quietly established for all new products, with no mutable
category segment. RideMate is a service/utility, so it does **not** take the legacy
`.games.` segment used by Chess Rescue and RPS Duel.

Identifiers verified in both native configurations at bootstrap; no `com.example.*`
remains anywhere in the tree (a defect present in `lang_app`, avoided here).

**Platform minimums.** Android `minSdk 24` and iOS `13.0` are the values Flutter
3.41.1 generates by default (`FlutterExtension.minSdkVersion = 24`,
`IPHONEOS_DEPLOYMENT_TARGET = 13.0`). They match the intended baseline exactly, so
**no native override is applied** — the generated settings stand.

## Sibling ecosystem context

- RPS Duel — game (legacy package `com.lunexa.games.rpsduel`; unchanged)
- Chess Rescue — game (legacy package `com.lunexa.games.chessrescue`; unchanged)
- Quietly — utility; first app on the unified `com.lunexa.*` root
- **RideMate — service; second app on the unified root**

## Release signing

**There is no debug-key fallback, by construction.** `android/app/build.gradle.kts`
creates a release signing config only when `android/key.properties` exists. If a release
task is requested without it, the build stops at configuration time with a message naming
the file and the keys it needs. The Flutter template line that signed release builds with
the shared debug key is gone, and `test/app/android_release_config_test.dart` asserts it
cannot come back.

Debug builds need no private material and are unaffected.

### Creating the upload key (owner action — not done by tooling)

```bash
keytool -genkey -v -keystore ~/keys/ridemate-upload.jks \
        -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties` — **git-ignored at the repository root and under
`android/`; never committed, never pasted into CI in this phase**:

```properties
storeFile=/absolute/path/to/ridemate-upload.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

Keep the keystore and its passwords outside the repository and backed up. **The upload key
cannot be replaced without Play's key-reset process**, so losing it is expensive.

### Deliberately unsigned artifacts

For structural verification only:

```bash
flutter build apk --release -Pridemate.allowUnsignedRelease=true
```

This is an explicitly named path so that "the release build succeeded" can never quietly
mean "unsigned". The artifact cannot be installed as an update or uploaded to Play —
verified with `apksigner verify`, which reports `DOES NOT VERIFY`.

## Open items before first publish

- [ ] Store title (must fit 30 chars on Play, 30 on App Store)
- [ ] Store category — likely *Travel & Local* (Play) / *Travel* (App Store)
- [ ] App icon (`flutter_launcher_icons` added at that point, not before)
- [ ] Data-safety / privacy-nutrition declarations — significant, since the product
      handles identity verification, live location and emergency contacts
- [ ] **Signing keystore.** The *mechanism* is prepared and fail-closed (see above), and
      the ignore rules are in place before any key exists. The item stays **open** until a
      real private upload keystore exists and a signed release artifact has been built and
      verified. Phase 7 could not and did not test real signing.
