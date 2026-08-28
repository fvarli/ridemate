@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/providers/session_provider.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/routes/ride_rule.dart';
import 'package:ridemate/core/theme/rm_theme.dart';
import 'package:ridemate/features/chat/presentation/chat_screen.dart';
import 'package:ridemate/features/create_route/application/place_catalogue_providers.dart';
import 'package:ridemate/features/create_route/presentation/create_route_screen.dart';
import 'package:ridemate/features/discovery/domain/mock_discovery_fixtures.dart';
import 'package:ridemate/features/discovery/presentation/match_results_screen.dart';
import 'package:ridemate/features/discovery/presentation/route_details_screen.dart';
import 'package:ridemate/features/discovery/presentation/search_screen.dart';
import 'package:ridemate/features/home/presentation/home_screen.dart';
import 'package:ridemate/features/my_routes/application/my_routes_providers.dart';
import 'package:ridemate/features/my_routes/data/my_routes_repository.dart';
import 'package:ridemate/features/my_routes/presentation/my_routes_screen.dart';
import 'package:ridemate/features/onboarding/application/onboarding_controller.dart';
import 'package:ridemate/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ridemate/features/profile/presentation/profile_screen.dart';
import 'package:ridemate/features/reviews/presentation/reviews_screen.dart';
import 'package:ridemate/features/safety/presentation/safety_screen.dart';
import 'package:ridemate/features/trip/presentation/active_trip_screen.dart';
import 'package:ridemate/features/verification/presentation/verification_screen.dart';
import 'package:ridemate/l10n/app_localizations.dart';

import '../support/fakes.dart';
import '../support/fonts.dart';

/// Golden coverage for the product screens.
///
/// Each screen is captured in light and dark, plus an RTL baseline for the
/// densest screen of each phase — Home for Phase 2, Match Results for Phase 3,
/// and both Profile and Safety for Phase 6.
/// Dark is covered for every screen deliberately: dark-mode drift is otherwise
/// invisible until someone opens the app at night.
///
/// HOST-DEPENDENT. Baselines were generated on Linux; font rasterization
/// differs across platforms. Excluded from the default run — see
/// dart_test.yaml and tool/goldens.sh.
void main() {
  setUpAll(loadRideMateFonts);

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    required Brightness brightness,
    TextDirection textDirection = TextDirection.ltr,
    bool disableAnimations = false,
  }) async {
    // A representative modern phone.
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          // Seed the intro as complete so nothing redirects mid-capture.
          onboardingRepositoryProvider.overrideWithValue(
            InMemoryOnboardingRepository(seen: true),
          ),
          rmSessionProvider.overrideWithValue(FakeSession()),
          // Create Route reads its endpoints from the server. A deterministic
          // catalogue keeps the capture stable — and keeps it honest, since
          // the screen has no fixture to fall back on.
          placeRepositoryProvider.overrideWithValue(FakePlaceRepository()),
          // My Routes reads the server too, and has no fixture to fall back
          // on. A fixed page keeps the capture deterministic and covers the
          // three things the card can say: upcoming, past and cancelled.
          myRoutesRepositoryProvider.overrideWithValue(
            FakeMyRoutesRepository(
              pages: <MyRoutesResult>[
                MyRoutesResult(
                  routes: <PublishedRoute>[
                    fakeRoute(
                      id: '01991b00-0000-7000-8000-000000000001',
                      originLabel: 'Kadıköy, Vapur İskelesi',
                      destinationLabel: 'Levent, Metro İstasyonu',
                      rules: const <RideRuleId>{
                        RideRuleId.noSmoking,
                        RideRuleId.quiet,
                      },
                    ),
                    fakeRoute(
                      id: '01991b00-0000-7000-8000-000000000002',
                      originLabel: 'Maslak, Atatürk Oto Sanayi',
                      destinationLabel: 'Ataşehir, Palladium',
                      recurrence: Recurrence.once,
                      departureDate: '2026-09-14',
                      departureTime: '18:10',
                      seatsOffered: 2,
                      rules: const <RideRuleId>{},
                      departureState: DepartureState.past,
                    ),
                    fakeRoute(
                      id: '01991b00-0000-7000-8000-000000000003',
                      originLabel: 'İTÜ Ayazağa, Metro İstasyonu',
                      destinationLabel: 'Kadıköy, Vapur İskelesi',
                      seatsOffered: 1,
                      status: RouteStatus.cancelled,
                      cancelledAt: '2026-08-27T18:00:00+00:00',
                    ),
                  ],
                  nextCursor: 'more',
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: RmTheme.of(brightness),
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Directionality(
            textDirection: textDirection,
            child: Builder(
              builder: (BuildContext context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: disableAnimations),
                child: screen,
              ),
            ),
          ),
        ),
      ),
    );

    // Fixed frames rather than pumpAndSettle: some surfaces animate forever
    // by design, and a fixed point also keeps the baselines stable.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('Onboarding', () {
    for (final Brightness brightness in Brightness.values) {
      testWidgets(brightness.name, (WidgetTester tester) async {
        await pump(tester, const OnboardingScreen(), brightness: brightness);
        await expectLater(
          find.byType(OnboardingScreen),
          matchesGoldenFile('goldens/onboarding_${brightness.name}.png'),
        );
      });
    }
  });

  group('Verification', () {
    for (final Brightness brightness in Brightness.values) {
      testWidgets(brightness.name, (WidgetTester tester) async {
        await pump(tester, const VerificationScreen(), brightness: brightness);
        await expectLater(
          find.byType(VerificationScreen),
          matchesGoldenFile('goldens/verification_${brightness.name}.png'),
        );
      });
    }
  });

  group('Home', () {
    for (final Brightness brightness in Brightness.values) {
      testWidgets(brightness.name, (WidgetTester tester) async {
        await pump(
          tester,
          const Scaffold(body: HomeScreen()),
          brightness: brightness,
        );
        await expectLater(
          find.byType(HomeScreen),
          matchesGoldenFile('goldens/home_${brightness.name}.png'),
        );
      });
    }

    testWidgets('right-to-left', (WidgetTester tester) async {
      // Arabic is a declared future locale; this proves the densest screen is
      // already mirror-safe before any Arabic strings exist.
      await pump(
        tester,
        const Scaffold(body: HomeScreen()),
        brightness: Brightness.light,
        textDirection: TextDirection.rtl,
      );
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_rtl.png'),
      );
    });
  });

  group('Search', () {
    for (final Brightness brightness in Brightness.values) {
      testWidgets(brightness.name, (WidgetTester tester) async {
        await pump(tester, const SearchScreen(), brightness: brightness);
        await expectLater(
          find.byType(SearchScreen),
          matchesGoldenFile('goldens/search_${brightness.name}.png'),
        );
      });
    }
  });

  group('Match results', () {
    for (final Brightness brightness in Brightness.values) {
      testWidgets(brightness.name, (WidgetTester tester) async {
        await pump(tester, const MatchResultsScreen(), brightness: brightness);
        await expectLater(
          find.byType(MatchResultsScreen),
          matchesGoldenFile('goldens/matches_${brightness.name}.png'),
        );
      });
    }

    testWidgets('right-to-left', (WidgetTester tester) async {
      // The densest Phase 3 screen: three card tiers, a meter and a sort row.
      await pump(
        tester,
        const MatchResultsScreen(),
        brightness: Brightness.light,
        textDirection: TextDirection.rtl,
      );
      await expectLater(
        find.byType(MatchResultsScreen),
        matchesGoldenFile('goldens/matches_rtl.png'),
      );
    });
  });

  group('Route details', () {
    for (final Brightness brightness in Brightness.values) {
      testWidgets(brightness.name, (WidgetTester tester) async {
        await pump(
          tester,
          RouteDetailsScreen(routeId: MockRouteOffers.selin.id),
          brightness: brightness,
        );
        await expectLater(
          find.byType(RouteDetailsScreen),
          matchesGoldenFile('goldens/route_details_${brightness.name}.png'),
        );
      });
    }
  });

  // Phase 5's two screens pump with animations disabled. Three of their
  // animations repeat forever, so a baseline taken mid-cycle would be pinning
  // an arbitrary frame; pinning them at rest also makes each image a test of
  // the reduced-motion path.
  group('Active trip', () {
    for (final Brightness brightness in Brightness.values) {
      testWidgets(brightness.name, (WidgetTester tester) async {
        await pump(
          tester,
          const ActiveTripScreen(),
          brightness: brightness,
          disableAnimations: true,
        );
        await expectLater(
          find.byType(ActiveTripScreen),
          matchesGoldenFile('goldens/active_trip_${brightness.name}.png'),
        );
      });
    }
  });

  group('Chat', () {
    for (final Brightness brightness in Brightness.values) {
      testWidgets(brightness.name, (WidgetTester tester) async {
        await pump(
          tester,
          const ChatScreen(),
          brightness: brightness,
          disableAnimations: true,
        );
        await expectLater(
          find.byType(ChatScreen),
          matchesGoldenFile('goldens/chat_${brightness.name}.png'),
        );
      });
    }

    testWidgets('right-to-left', (WidgetTester tester) async {
      // The densest directional screen of the phase: the bubbles' tight corner
      // follows the reading axis, the header mirrors, and the send glyph is one
      // of only three icons that flip.
      await pump(
        tester,
        const ChatScreen(),
        brightness: Brightness.light,
        textDirection: TextDirection.rtl,
        disableAnimations: true,
      );
      await expectLater(
        find.byType(ChatScreen),
        matchesGoldenFile('goldens/chat_rtl.png'),
      );
    });
  });

  group('Profile', () {
    for (final Brightness brightness in Brightness.values) {
      testWidgets(brightness.name, (WidgetTester tester) async {
        await pump(tester, const ProfileScreen(), brightness: brightness);
        await expectLater(
          find.byType(ProfileScreen),
          matchesGoldenFile('goldens/profile_${brightness.name}.png'),
        );
      });
    }

    testWidgets('right-to-left', (WidgetTester tester) async {
      // The densest screen of the phase, and the only one anywhere with a
      // negative-margin overlap: the trust card rides up over the header, and
      // the breakdown's measured columns have to mirror with it.
      await pump(
        tester,
        const ProfileScreen(),
        brightness: Brightness.light,
        textDirection: TextDirection.rtl,
      );
      await expectLater(
        find.byType(ProfileScreen),
        matchesGoldenFile('goldens/profile_rtl.png'),
      );
    });
  });

  group('Reviews', () {
    for (final Brightness brightness in Brightness.values) {
      testWidgets(brightness.name, (WidgetTester tester) async {
        await pump(tester, const ReviewsScreen(), brightness: brightness);
        await expectLater(
          find.byType(ReviewsScreen),
          matchesGoldenFile('goldens/reviews_${brightness.name}.png'),
        );
      });
    }
  });

  // The SOS halo repeats forever, so these capture with animations disabled:
  // a baseline taken mid-cycle would pin an arbitrary frame, and pinning it
  // at rest also makes each image a test of the reduced-motion path.
  group('Safety center', () {
    for (final Brightness brightness in Brightness.values) {
      testWidgets(brightness.name, (WidgetTester tester) async {
        await pump(
          tester,
          const SafetyScreen(),
          brightness: brightness,
          disableAnimations: true,
        );
        await expectLater(
          find.byType(SafetyScreen),
          matchesGoldenFile('goldens/safety_${brightness.name}.png'),
        );
      });
    }

    testWidgets('right-to-left', (WidgetTester tester) async {
      // Three chevron rows and two tinted tiles: the classic mirroring bug.
      // Its SOS card is feature-local, so it never reaches the gallery's own
      // review surface either.
      await pump(
        tester,
        const SafetyScreen(),
        brightness: Brightness.light,
        textDirection: TextDirection.rtl,
        disableAnimations: true,
      );
      await expectLater(
        find.byType(SafetyScreen),
        matchesGoldenFile('goldens/safety_rtl.png'),
      );
    });
  });

  group('My routes', () {
    for (final Brightness brightness in Brightness.values) {
      testWidgets(brightness.name, (WidgetTester tester) async {
        await pump(tester, const MyRoutesScreen(), brightness: brightness);
        // The page arrives a frame later.
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MyRoutesScreen),
          matchesGoldenFile('goldens/my_routes_${brightness.name}.png'),
        );
      });
    }

    /// A card mixes a directional route line, chips, a status pill and a
    /// trailing action — the combination most likely to break when mirrored.
    testWidgets('right-to-left', (WidgetTester tester) async {
      await pump(
        tester,
        const MyRoutesScreen(),
        brightness: Brightness.light,
        textDirection: TextDirection.rtl,
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MyRoutesScreen),
        matchesGoldenFile('goldens/my_routes_rtl.png'),
      );
    });
  });

  group('Create route', () {
    for (final Brightness brightness in Brightness.values) {
      testWidgets(brightness.name, (WidgetTester tester) async {
        await pump(tester, const CreateRouteScreen(), brightness: brightness);
        // The catalogue arrives a frame later.
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(CreateRouteScreen),
          matchesGoldenFile('goldens/create_route_${brightness.name}.png'),
        );
      });
    }

    testWidgets('right-to-left', (WidgetTester tester) async {
      // Mandatory rather than optional here. This is the only screen with
      // directional form controls, and its switch and stepper are
      // feature-local, so they never reach the gallery's review surface.
      await pump(
        tester,
        const CreateRouteScreen(),
        brightness: Brightness.light,
        textDirection: TextDirection.rtl,
      );
      await expectLater(
        find.byType(CreateRouteScreen),
        matchesGoldenFile('goldens/create_route_rtl.png'),
      );
    });
  });
}
