import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/journeys/journey.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/my_route.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/routes/ride_rule.dart';
import 'package:ridemate/core/trips/trip_lifecycle.dart';
import 'package:ridemate/core/widgets/rm_button.dart';
import 'package:ridemate/features/journeys/application/journeys_providers.dart';
import 'package:ridemate/features/my_routes/application/my_routes_providers.dart';
import 'package:ridemate/features/my_routes/data/my_routes_repository.dart';
import 'package:ridemate/features/my_routes/presentation/my_routes_screen.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/pump.dart';

/// The screen a driver sees after publishing, and the one place they can
/// withdraw a journey.
void main() {
  setUpAll(loadRideMateFonts);

  late FakeMyRoutesRepository routes;

  Future<void> pump(
    WidgetTester tester, {
    List<MyRoutesResult>? pages,
    RmFailure? failure,
    List<Journey> journeys = const <Journey>[],
    TextDirection textDirection = TextDirection.ltr,
    Locale locale = kDefaultTestLocale,
    Size size = const Size(393, 852),
  }) async {
    routes = FakeMyRoutesRepository(pages: pages, failure: failure);

    await tester.pumpRm(
      const MyRoutesScreen(),
      textDirection: textDirection,
      locale: locale,
      surfaceSize: size,
      overrides: <Override>[
        myRoutesRepositoryProvider.overrideWithValue(routes),
        // The screen also carries the dated journey feed, which is a different
        // endpoint with a different failure. Stubbed empty unless a case says
        // otherwise, so a test about the ROUTE list is not also a test about
        // what happens when the journeys endpoint is unreachable.
        journeysRepositoryProvider.overrideWithValue(
          FakeJourneys(journeys: journeys),
        ),
      ],
    );
    // Twice: the first frame is the loading state, the second the answer.
    await tester.pump();
    await tester.pump();
  }

  MyRoutesResult page(List<MyRoute> routes, {String? next}) =>
      MyRoutesResult(routes: routes, nextCursor: next);

  group('What the list shows', () {
    testWidgets('a published journey, as the server described it', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(
              originLabel: 'Kadıköy, Vapur İskelesi',
              destinationLabel: 'Levent, Metro İstasyonu',
              seatsOffered: 3,
            ),
          ]),
        ],
      );

      expect(
        find.text('Kadıköy, Vapur İskelesi → Levent, Metro İstasyonu'),
        findsOneWidget,
      );
      expect(find.textContaining('08:25'), findsOneWidget);
      expect(find.textContaining('Her hafta içi'), findsOneWidget);
      expect(find.text('Yayında'), findsOneWidget);
    });

    /// CARRIES WEIGHT. Offered, never available.
    ///
    /// Nothing has requested a seat — there is no seat-request model at all —
    /// so a count described as "free" or "left" would be a claim the server
    /// cannot back.
    testWidgets('seats are described as offered', (WidgetTester tester) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute(seatsOffered: 3)]),
        ],
      );

      expect(find.text('3 koltuk sunuluyor'), findsOneWidget);
      for (final String forbidden in <String>['BOŞ KOLTUK', 'Boş koltuk']) {
        expect(find.textContaining(forbidden), findsNothing, reason: forbidden);
      }
    });

    testWidgets('a one-off journey names its date', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(
              recurrence: Recurrence.once,
              departureDate: '2099-04-01',
              departureTime: '18:10',
            ),
          ]),
        ],
      );

      expect(find.textContaining('2099-04-01'), findsOneWidget);
      expect(find.textContaining('18:10'), findsOneWidget);
      expect(find.textContaining('Her hafta içi'), findsNothing);
    });

    testWidgets('routes render in the order the server sent them', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(id: 'a', originLabel: 'Birinci'),
            fakeMyRoute(id: 'b', originLabel: 'İkinci'),
            fakeMyRoute(id: 'c', originLabel: 'Üçüncü'),
          ]),
        ],
        // Tall enough for all three at once. The list is lazy, so a card below
        // the viewport is never built — and this is about the order they come
        // in, not about how many fit on a phone.
        size: const Size(393, 1400),
      );

      final double first = tester.getTopLeft(find.textContaining('Birinci')).dy;
      final double second = tester.getTopLeft(find.textContaining('İkinci')).dy;
      final double third = tester.getTopLeft(find.textContaining('Üçüncü')).dy;

      expect(first, lessThan(second));
      expect(second, lessThan(third));
    });
  });

  group('Ride rules', () {
    testWidgets('only the rules the driver selected appear', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(
              rules: <RideRuleId>{RideRuleId.noSmoking, RideRuleId.quiet},
            ),
          ]),
        ],
      );

      expect(find.text('Sigara yok'), findsOneWidget);
      expect(find.text('Sessiz'), findsOneWidget);
      expect(find.text('Müzik OK'), findsNothing);
      expect(find.text('Evcil hayvan yok'), findsNothing);
    });

    /// CARRIES WEIGHT. A rule that is off is not the opposite rule.
    ///
    /// `no_pets: false` says the driver did not select that rule. It does not
    /// say pets are welcome, and putting an affirmative chip on the card would
    /// be a promise nobody made.
    testWidgets('an unselected rule never becomes its inverse', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute(rules: const <RideRuleId>{})]),
        ],
      );

      for (final String invented in <String>[
        'Evcil hayvan',
        'Sigara',
        'Müzik',
        'Sessiz',
        'kabul',
        'serbest',
        'izin',
      ]) {
        expect(find.textContaining(invented), findsNothing, reason: invented);
      }
    });

    testWidgets('no selected rule means no chip row at all', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute(rules: const <RideRuleId>{})]),
        ],
      );

      // The card still renders everything else.
      expect(find.textContaining('Sunucu Yeri'), findsOneWidget);
      expect(find.text('3 koltuk sunuluyor'), findsOneWidget);
    });
  });

  group('Cancel appears only when the server allows it', () {
    testWidgets('published and upcoming offers Cancel', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(
              status: RouteStatus.published,
              departureState: DepartureState.upcoming,
            ),
          ]),
        ],
      );

      expect(find.text('Rotayı iptal et'), findsOneWidget);
    });

    /// The server decided this journey has departed. Offering to withdraw it
    /// would offer something the API refuses.
    testWidgets('published but past hides Cancel', (WidgetTester tester) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(
              recurrence: Recurrence.once,
              departureDate: '2020-01-01',
              status: RouteStatus.published,
              departureState: DepartureState.past,
            ),
          ]),
        ],
      );

      expect(find.text('Rotayı iptal et'), findsNothing);
      expect(find.text('Geçmiş'), findsOneWidget);
    });

    testWidgets('an already cancelled route hides Cancel', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(
              status: RouteStatus.cancelled,
              cancelledAt: '2026-08-28T10:00:00+00:00',
            ),
          ]),
        ],
      );

      expect(find.text('Rotayı iptal et'), findsNothing);
      expect(find.text('İptal edildi'), findsOneWidget);
    });

    /// A weekday commute has no single departure to be past, so the server
    /// keeps calling it upcoming however much time passes — and Cancel stays.
    testWidgets('a weekday commute stays cancellable', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(
              recurrence: Recurrence.weekdays,
              departureState: DepartureState.upcoming,
            ),
          ]),
        ],
      );

      expect(find.text('Rotayı iptal et'), findsOneWidget);
    });
  });

  group('Cancelling', () {
    Future<void> tapCancel(WidgetTester tester) async {
      await tester.tap(find.text('Rotayı iptal et'));
      await tester.pumpAndSettle();
    }

    /// CARRIES WEIGHT. Withdrawing a journey is asked for, never assumed.
    testWidgets('nothing is sent until the member confirms', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute(id: 'a')]),
        ],
      );

      await tapCancel(tester);

      expect(find.text('Bu rota iptal edilsin mi?'), findsOneWidget);
      expect(routes.cancelled, isEmpty);

      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();

      expect(routes.cancelled, isEmpty);
      expect(find.text('Rotayı iptal et'), findsOneWidget);
    });

    testWidgets('confirming withdraws exactly that route', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(id: 'a', originLabel: 'Birinci'),
            fakeMyRoute(id: 'b', originLabel: 'İkinci'),
          ]),
        ],
      );
      routes.cancelResult = fakeRoute(
        id: 'a',
        originLabel: 'Birinci',
        status: RouteStatus.cancelled,
        cancelledAt: '2026-08-28T10:00:00+00:00',
      );

      await tester.tap(find.text('Rotayı iptal et').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Evet, iptal et'));
      await tester.pumpAndSettle();

      expect(routes.cancelled, <String>['a']);
      expect(find.text('Rota iptal edildi.'), findsOneWidget);
      // Replaced, not removed: the journey stays in the member's history.
      expect(find.textContaining('Birinci'), findsOneWidget);
      expect(find.text('İptal edildi'), findsOneWidget);
      // The other route is untouched and still cancellable.
      expect(find.text('Rotayı iptal et'), findsOneWidget);
    });

    testWidgets('a failure leaves the route exactly as it was', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute(id: 'a')]),
        ],
      );
      routes.cancelFailure = const RmFailure.transport();

      await tapCancel(tester);
      await tester.tap(find.text('Evet, iptal et'));
      await tester.pumpAndSettle();

      expect(find.text('Rota iptal edildi.'), findsNothing);
      expect(find.text('İptal edildi'), findsNothing);
      // Still published, still offering the action, ready to try again.
      expect(find.text('Yayında'), findsOneWidget);
      expect(find.text('Rotayı iptal et'), findsOneWidget);
    });

    /// A conflict means the departure has passed. It is not a cancellation.
    testWidgets('a conflict is stated, not faked', (WidgetTester tester) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute(id: 'a')]),
        ],
      );
      routes.cancelFailure = const RmFailure.fromBackend(
        status: 409,
        code: RmErrorCode.conflict,
      );

      await tapCancel(tester);
      await tester.tap(find.text('Evet, iptal et'));
      await tester.pumpAndSettle();

      expect(find.text('Yayında'), findsOneWidget);
      expect(find.text('İptal edildi'), findsNothing);
    });

    /// A 404 says the server would not act on that id. It is not evidence
    /// about what this member has, so nothing is removed.
    testWidgets('a not-found removes nothing from the list', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(id: 'a', originLabel: 'Birinci'),
            fakeMyRoute(id: 'b', originLabel: 'İkinci'),
          ]),
        ],
      );
      routes.cancelFailure = const RmFailure.fromBackend(
        status: 404,
        code: RmErrorCode.notFound,
      );

      await tester.tap(find.text('Rotayı iptal et').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Evet, iptal et'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Birinci'), findsOneWidget);
      expect(find.textContaining('İkinci'), findsOneWidget);
    });

    testWidgets('only the target route shows as busy', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(id: 'a', originLabel: 'Birinci'),
            fakeMyRoute(id: 'b', originLabel: 'İkinci'),
          ]),
        ],
      );

      await tester.tap(find.text('Rotayı iptal et').first);
      await tester.pumpAndSettle();
      routes.hold();
      await tester.tap(find.text('Evet, iptal et'));
      // Explicit pumps, not pumpAndSettle: the busy button animates, so
      // "settled" never arrives while the request is in flight — which is
      // precisely the moment this test is about.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final List<RmButton> buttons = tester
          .widgetList<RmButton>(find.byType(RmButton))
          .toList();
      expect(buttons.where((RmButton b) => b.loading), hasLength(1));
      // The other card is still readable and still actionable.
      expect(find.textContaining('İkinci'), findsOneWidget);
      expect(find.text('Rotayı iptal et'), findsOneWidget);

      routes.release();
      await tester.pumpAndSettle();
    });
  });

  group('Loading more', () {
    testWidgets('the control appears only while the server offers more', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute(id: 'a')], next: 'more'),
          page(<MyRoute>[fakeMyRoute(id: 'b', originLabel: 'İkinci')]),
        ],
      );

      expect(find.text('Daha fazla yükle'), findsOneWidget);

      await tester.tap(find.text('Daha fazla yükle'));
      await tester.pumpAndSettle();

      expect(find.textContaining('İkinci'), findsOneWidget);
      // The server stopped offering a position, so the control is gone.
      expect(find.text('Daha fazla yükle'), findsNothing);
    });

    testWidgets('there is no control when the first page is the last', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute()]),
        ],
      );

      expect(find.text('Daha fazla yükle'), findsNothing);
    });

    /// CARRIES WEIGHT. Page two failing must not cost the member page one.
    testWidgets('a failure keeps the routes already on screen', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(id: 'a', originLabel: 'Birinci'),
          ], next: 'more'),
        ],
      );
      routes.failure = const RmFailure.transport();

      await tester.tap(find.text('Daha fazla yükle'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Birinci'), findsOneWidget);
      expect(find.text('Sonraki sayfa yüklenemedi.'), findsOneWidget);
      // The same position can be asked for again.
      expect(find.text('Yeniden dene'), findsOneWidget);
    });

    testWidgets('repeated taps make one request', (WidgetTester tester) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute(id: 'a')], next: 'more'),
          page(<MyRoute>[fakeMyRoute(id: 'b')]),
        ],
      );
      routes.hold();

      await tester.tap(find.text('Daha fazla yükle'));
      await tester.tap(find.text('Daha fazla yükle'));
      await tester.pump();

      // One for the first page, one for the load-more.
      expect(routes.callCount, 2);

      routes.release();
      await tester.pumpAndSettle();
    });
  });

  group('When there is nothing, or nothing works', () {
    testWidgets('an empty account says so and invents nothing', (
      WidgetTester tester,
    ) async {
      await pump(tester, pages: <MyRoutesResult>[page(<MyRoute>[])]);

      expect(find.text('Henüz rota yayınlamadın'), findsOneWidget);
      expect(find.text('Rotayı iptal et'), findsNothing);
      expect(find.text('Daha fazla yükle'), findsNothing);
    });

    testWidgets('a failure is stated and can be retried', (
      WidgetTester tester,
    ) async {
      await pump(tester, failure: const RmFailure.transport());

      expect(find.text('Yeniden dene'), findsOneWidget);
      expect(find.text('Henüz rota yayınlamadın'), findsNothing);

      routes
        ..failure = null
        ..chain(<MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute(originLabel: 'Gerçek')]),
        ]);

      await tester.tap(find.text('Yeniden dene'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gerçek'), findsOneWidget);
    });

    /// CARRIES WEIGHT. No fixture, ever.
    ///
    /// A route nobody published, on the screen that exists to show what you
    /// published, is the exact lie Phase 10 was built to remove.
    testWidgets('an unreachable backend shows no route at all', (
      WidgetTester tester,
    ) async {
      await pump(tester, failure: const RmFailure.transport());

      for (final String fixture in <String>[
        'Ataşehir',
        'Maslak',
        'Kadıköy',
        'Levent',
        '₺',
        '18',
        'Selin',
        'Mehmet',
      ]) {
        expect(find.textContaining(fixture), findsNothing, reason: fixture);
      }
    });
  });

  group('Nothing the server does not own', () {
    testWidgets('no cost, no person, no vehicle, no score', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(
              rules: <RideRuleId>{RideRuleId.noSmoking, RideRuleId.quiet},
            ),
          ]),
        ],
      );

      for (final String forbidden in <String>[
        '₺',
        'TL',
        'puan',
        'Doğrulanmış',
        'Güven',
        'plaka',
        'uyum',
        'dk yürüme',
        'Selin',
      ]) {
        expect(find.textContaining(forbidden), findsNothing, reason: forbidden);
      }

      // The trip COUNT, which is a trust signal RideMate does not have — see
      // routeDetailsRatingSummary, "{rating} · {trips} yolculuk", where the
      // fixture still has one. It is the NUMBER that is forbidden, not the
      // word: Phase 14 gave the word an honest use on this card, and Phase 16b
      // gave it another — the journeys section above names the dated journeys
      // running today, and counts none of them.
      expect(
        find.textContaining(RegExp(r'[0-9]+\s*yolculuk')),
        findsNothing,
        reason: 'a trip count',
      );
    });

    /// The payload carries a timezone. The screen has no use for one, and
    /// drawing it would invite someone to compute with it.
    testWidgets('the timezone is decoded but never drawn', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute()]),
        ],
      );

      expect(find.textContaining('Europe/Istanbul'), findsNothing);
      expect(find.textContaining('UTC'), findsNothing);
    });
  });

  group('Accessibility and direction', () {
    testWidgets('a card reads as one thing, with its status', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(
              originLabel: 'Kadıköy, Vapur İskelesi',
              destinationLabel: 'Levent, Metro İstasyonu',
            ),
          ]),
        ],
      );

      expect(
        find.bySemanticsLabel(
          RegExp(r'Kadıköy, Vapur İskelesi → Levent, Metro İstasyonu.*Yayında'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'rotasını iptal et')),
        findsOneWidget,
      );
      // CARRIES WEIGHT. The lifecycle line sits inside the excluded subtree,
      // so it reaches a screen reader only through the card's own label.
      expect(
        find.bySemanticsLabel(RegExp(r'Yayında.*Yolculuk: Başlamadı')),
        findsOneWidget,
      );
      // And the action names the journey it belongs to.
      expect(
        find.bySemanticsLabel(RegExp(r'yolculuğunu başlat')),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('renders in English, RTL and at the narrow width', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(
              rules: <RideRuleId>{RideRuleId.noSmoking, RideRuleId.quiet},
            ),
          ], next: 'more'),
        ],
        textDirection: TextDirection.rtl,
        locale: const Locale('en'),
        size: const Size(360, 800),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('offering 3 seats'), findsOneWidget);
      expect(find.text('Cancel route'), findsOneWidget);
      expect(find.text('Load more'), findsOneWidget);
    });
  });

  group('Whether the journey was made', () {
    /// Every state the server can name reaches the screen as its own sentence.
    testWidgets('each of the four states says what it means', (
      WidgetTester tester,
    ) async {
      for (final (TripState state, String copy) in <(TripState, String)>[
        (TripState.notStarted, 'Yolculuk: Başlamadı'),
        (TripState.inProgress, 'Yolculuk: Başladı'),
        (TripState.completed, 'Yolculuk: Tamamlandı'),
        (TripState.aborted, 'Yolculuk: Yarıda bırakıldı'),
      ]) {
        await pump(
          tester,
          pages: <MyRoutesResult>[
            page(<MyRoute>[
              fakeMyRoute(trip: state, startedAt: '2026-09-11T07:05:00Z'),
            ]),
          ],
        );

        expect(find.text(copy), findsOneWidget, reason: state.wire);
        // And never the wire string itself.
        expect(
          find.textContaining(state.wire),
          findsNothing,
          reason: state.wire,
        );
      }
    });

    /// CARRIES WEIGHT. `in_progress` says the driver pressed Start and the
    /// server accepted it. It does not say anybody is moving or anywhere.
    testWidgets('a started journey claims nothing about the world', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(
              trip: TripState.inProgress,
              startedAt: '2026-09-11T07:05:00Z',
            ),
          ]),
        ],
      );

      for (final String absent in <String>[
        'Yolda',
        'Sürüyor',
        'Hareket halinde',
        'Konum',
        'Harita',
        'Navigasyon',
        'Yolcu bindi',
        'Araçta',
        'GPS',
      ]) {
        expect(find.textContaining(absent), findsNothing, reason: absent);
      }
    });
  });

  group('Start is offered on the lifecycle, and on nothing else', () {
    testWidgets('a journey nobody started offers Start', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute()]),
        ],
      );

      expect(find.text('Yolculuğu başlat'), findsOneWidget);
    });

    testWidgets('a journey already in one of the three others does not', (
      WidgetTester tester,
    ) async {
      for (final TripState state in <TripState>[
        TripState.inProgress,
        TripState.completed,
        TripState.aborted,
      ]) {
        await pump(
          tester,
          pages: <MyRoutesResult>[
            page(<MyRoute>[
              fakeMyRoute(trip: state, startedAt: '2026-09-11T07:05:00Z'),
            ]),
          ],
        );

        expect(find.text('Yolculuğu başlat'), findsNothing, reason: state.wire);
      }
    });

    /// CARRIES WEIGHT. The backend requires the departure to have been
    /// reached, so a journey the server calls `past` is exactly one that CAN
    /// be started. Hiding Start there — as Cancel is rightly hidden — would
    /// take the command away at the only moment it works.
    testWidgets('a departed journey still offers Start', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(
              recurrence: Recurrence.once,
              departureDate: '2020-01-01',
              departureState: DepartureState.past,
            ),
          ]),
        ],
      );

      expect(find.text('Yolculuğu başlat'), findsOneWidget);
      expect(find.text('Rotayı iptal et'), findsNothing);
    });

    /// And a withdrawn one too: whether it may be started is the server's
    /// answer, and it has one — `route_unavailable`.
    testWidgets('a withdrawn journey still offers Start', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(
              status: RouteStatus.cancelled,
              cancelledAt: '2026-08-28T10:00:00+00:00',
            ),
          ]),
        ],
      );

      expect(find.text('Yolculuğu başlat'), findsOneWidget);
    });
  });

  group('Starting', () {
    Future<void> tapStart(WidgetTester tester) async {
      await tester.tap(find.text('Yolculuğu başlat').first);
      await tester.pumpAndSettle();
    }

    /// No confirmation: starting takes nothing away from anybody.
    testWidgets('one tap sends the command for that route', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(id: 'a', originLabel: 'Birinci'),
            fakeMyRoute(id: 'b', originLabel: 'İkinci'),
          ]),
        ],
        size: const Size(393, 1400),
      );

      await tester.tap(find.text('Yolculuğu başlat').last);
      await tester.pumpAndSettle();

      expect(routes.tripCommands, <String>['start b']);
    });

    /// CARRIES WEIGHT. The row shows what the server returned, never what the
    /// command was assumed to have done.
    testWidgets('the row takes the lifecycle the server answered with', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute()]),
        ],
      );
      routes.tripResult = fakeTrip(
        state: TripState.inProgress,
        startedAt: '2026-09-11T07:05:00Z',
      );

      await tapStart(tester);

      expect(find.text('Yolculuk: Başladı'), findsOneWidget);
      // And the control is gone, because the lifecycle moved.
      expect(find.text('Yolculuğu başlat'), findsNothing);
    });

    testWidgets('nothing moves before the server has answered', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute()]),
        ],
      );

      routes.hold();
      await tester.tap(find.text('Yolculuğu başlat'));
      await tester.pump();

      // Busy, and still not started. RmButton hides its label while loading,
      // so the control being gone is what "in flight" looks like here.
      expect(find.text('Yolculuk: Başlamadı'), findsOneWidget);
      expect(find.text('Yolculuğu başlat'), findsNothing);

      routes.release();
      await tester.pumpAndSettle();
    });

    /// The control is unreachable while the command is in flight, so a second
    /// tap cannot be aimed at it. That a second call would be refused anyway is
    /// the controller's own guarantee — see my_routes_state_test.dart.
    testWidgets('the control is gone while one command is in flight', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute()]),
        ],
      );

      routes.hold();
      await tester.tap(find.text('Yolculuğu başlat'));
      await tester.pump();

      expect(find.text('Yolculuğu başlat'), findsNothing);
      expect(routes.tripCommands, <String>[
        'start 01991b00-0000-7000-8000-000000000001',
      ]);

      routes.release();
      await tester.pumpAndSettle();
    });

    /// One journey being started does not take the control away from another.
    testWidgets('only the target card shows as busy', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            fakeMyRoute(id: 'a', originLabel: 'Birinci'),
            fakeMyRoute(id: 'b', originLabel: 'İkinci'),
          ]),
        ],
        size: const Size(393, 1400),
      );

      routes.hold();
      await tester.tap(find.text('Yolculuğu başlat').first);
      await tester.pump();

      // One control left, on the card that was not tapped.
      expect(find.text('Yolculuğu başlat'), findsOneWidget);

      routes.release();
      await tester.pumpAndSettle();
    });
  });

  group('When the server will not start it', () {
    Future<void> refuse(WidgetTester tester, TripRefusal refusal) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute()]),
        ],
      );
      routes.tripFailure = RmFailure.fromBackend(
        status: 409,
        code: RmErrorCode.conflict,
        reason: refusal.wire,
      );

      await tester.tap(find.text('Yolculuğu başlat'));
      await tester.pumpAndSettle();
    }

    /// CARRIES WEIGHT. Each reason gets its own sentence, chosen from the
    /// machine string — not from the status, which all six share.
    testWidgets('each reachable refusal says its own thing', (
      WidgetTester tester,
    ) async {
      for (final (TripRefusal refusal, String copy) in <(TripRefusal, String)>[
        (TripRefusal.departureNotReached, 'Bu yolculuk henüz başlatılamaz.'),
        // Not "not supported yet" since F3: the dated command exists and the
        // journeys section is where a plan's day is begun. What the route-only
        // alias refuses is a plan with no day named, and the sentence says
        // exactly that.
        (
          TripRefusal.recurringRouteUnsupported,
          'Hangi günü kastettiğini seç ve yolculuğu oradan başlat.',
        ),
        (TripRefusal.routeUnavailable, 'Bu rota artık başlatılamaz.'),
        (TripRefusal.alreadyCompleted, 'Bu yolculuk zaten tamamlanmış.'),
        (TripRefusal.alreadyAborted, 'Bu yolculuk zaten yarıda bırakılmış.'),
      ]) {
        await refuse(tester, refusal);

        expect(find.text(copy), findsOneWidget, reason: refusal.wire);
      }
    });

    /// CARRIES WEIGHT. A refusal is not a state change.
    testWidgets('the three non-terminal refusals leave the row alone', (
      WidgetTester tester,
    ) async {
      for (final TripRefusal refusal in <TripRefusal>[
        TripRefusal.departureNotReached,
        TripRefusal.recurringRouteUnsupported,
        TripRefusal.routeUnavailable,
      ]) {
        await refuse(tester, refusal);

        expect(
          find.text('Yolculuk: Başlamadı'),
          findsOneWidget,
          reason: refusal.wire,
        );
        expect(
          find.text('Yolculuğu başlat'),
          findsOneWidget,
          reason: 'the command is still offered: ${refusal.wire}',
        );
        // And nothing is re-read: these say what the journey already is, so
        // the row on screen was never stale.
        expect(routes.callCount, 1, reason: 'no re-read for ${refusal.wire}');
      }
    });

    /// CARRIES WEIGHT. `already_completed` says WHICH ending happened and
    /// nothing about when. Rendering one from the reason would put a state on
    /// screen that no response carried.
    testWidgets('a terminal conflict is re-read, never invented', (
      WidgetTester tester,
    ) async {
      for (final TripRefusal refusal in <TripRefusal>[
        TripRefusal.alreadyCompleted,
        TripRefusal.alreadyAborted,
      ]) {
        await refuse(tester, refusal);

        // The fake still answers `not_started`, so the re-read brings that
        // back. What matters is that nothing synthesised an ending.
        expect(find.text('Yolculuk: Tamamlandı'), findsNothing);
        expect(find.text('Yolculuk: Yarıda bırakıldı'), findsNothing);
        expect(
          routes.callCount,
          greaterThan(1),
          reason: 'a stale row is re-read from the server: ${refusal.wire}',
        );
      }
    });

    /// A reason this build has never heard of, and a failure with none at all,
    /// both land on the existing generic copy rather than on a guess.
    testWidgets('anything else falls to the generic seam', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute()]),
        ],
      );
      routes.tripFailure = const RmFailure.fromBackend(
        status: 409,
        code: RmErrorCode.conflict,
        reason: 'trip_already_started',
      );

      await tester.tap(find.text('Yolculuğu başlat'));
      await tester.pumpAndSettle();

      expect(find.text('Yolculuk: Başlamadı'), findsOneWidget);
      // The conflict copy the app already owns, not a sentence about trips.
      expect(find.textContaining('yolculuk zaten'), findsNothing);
    });

    /// CARRIES WEIGHT. The backend's `message` is developer-facing English the
    /// contract forbids displaying — and RmFailure does not even carry it.
    testWidgets('the server message never reaches the screen', (
      WidgetTester tester,
    ) async {
      await refuse(tester, TripRefusal.departureNotReached);

      for (final String english in <String>[
        'The scheduled departure has not been reached',
        'departure',
        'timezone',
        'conflict',
        '409',
      ]) {
        expect(find.textContaining(english), findsNothing, reason: english);
      }
    });
  });

  group('Ending a journey', () {
    MyRoute running() => fakeMyRoute(
      trip: TripState.inProgress,
      startedAt: '2026-09-11T07:05:00Z',
      recurrence: Recurrence.once,
      departureDate: '2026-09-11',
      departureState: DepartureState.past,
    );

    testWidgets('a running journey offers both endings and no Start', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[running()]),
        ],
      );

      expect(find.text('Yolculuğu tamamla'), findsOneWidget);
      expect(find.text('Yolculuğu yarıda bırak'), findsOneWidget);
      expect(find.text('Yolculuğu başlat'), findsNothing);
      // A journey under way has departed, so withdrawing it is already gone.
      expect(find.text('Rotayı iptal et'), findsNothing);
    });

    testWidgets('an unstarted journey offers neither ending', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[fakeMyRoute()]),
        ],
      );

      expect(find.text('Yolculuğu tamamla'), findsNothing);
      expect(find.text('Yolculuğu yarıda bırak'), findsNothing);
    });

    /// CARRIES WEIGHT. A journey that has ended has no lifecycle command left.
    testWidgets('a terminal journey offers no lifecycle command at all', (
      WidgetTester tester,
    ) async {
      for (final TripState state in <TripState>[
        TripState.completed,
        TripState.aborted,
      ]) {
        await pump(
          tester,
          pages: <MyRoutesResult>[
            page(<MyRoute>[
              fakeMyRoute(trip: state, startedAt: '2026-09-11T07:05:00Z'),
            ]),
          ],
        );

        for (final String control in <String>[
          'Yolculuğu başlat',
          'Yolculuğu tamamla',
          'Yolculuğu yarıda bırak',
        ]) {
          expect(
            find.text(control),
            findsNothing,
            reason: '${state.wire}: $control',
          );
        }
      }
    });

    /// Two running journeys, and the SECOND is tapped: a control wired to the
    /// wrong row would pass against a single-card list and fail here.
    MyRoutesResult twoRunning() => page(<MyRoute>[
      running(),
      fakeMyRoute(
        id: 'b',
        originLabel: 'İkinci',
        trip: TripState.inProgress,
        startedAt: '2026-09-11T07:05:00Z',
        recurrence: Recurrence.once,
        departureDate: '2026-09-11',
        departureState: DepartureState.past,
      ),
    ]);

    testWidgets('completing sends that route id and renders the answer', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[twoRunning()],
        size: const Size(393, 1600),
      );

      await tester.tap(find.text('Yolculuğu tamamla').last);
      await tester.pumpAndSettle();

      expect(routes.tripCommands, <String>['complete b']);
      expect(find.text('Yolculuk: Tamamlandı'), findsOneWidget);
      // And the journey that was not tapped is untouched.
      expect(find.text('Yolculuk: Başladı'), findsOneWidget);
    });

    testWidgets('abandoning sends that route id and renders the answer', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[twoRunning()],
        size: const Size(393, 1600),
      );

      await tester.tap(find.text('Yolculuğu yarıda bırak').last);
      await tester.pumpAndSettle();

      expect(routes.tripCommands, <String>['abort b']);
      expect(find.text('Yolculuk: Yarıda bırakıldı'), findsOneWidget);
      expect(find.text('Yolculuk: Başladı'), findsOneWidget);
    });

    /// CARRIES WEIGHT. No reason is asked for, because none is stored.
    testWidgets('abandoning never asks why', (WidgetTester tester) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[running()]),
        ],
      );

      await tester.tap(find.text('Yolculuğu yarıda bırak'));
      await tester.pump();

      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('nothing moves before the server has answered', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[running()]),
        ],
      );

      routes.hold();
      await tester.tap(find.text('Yolculuğu tamamla'));
      await tester.pump();

      expect(find.text('Yolculuk: Başladı'), findsOneWidget);
      expect(find.text('Yolculuk: Tamamlandı'), findsNothing);

      routes.release();
      await tester.pumpAndSettle();
    });

    /// One journey ending does not take the controls away from another.
    testWidgets('only the target card is busy', (WidgetTester tester) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[
            running(),
            fakeMyRoute(
              id: 'b',
              originLabel: 'İkinci',
              trip: TripState.inProgress,
              startedAt: '2026-09-11T07:05:00Z',
              recurrence: Recurrence.once,
              departureDate: '2026-09-11',
              departureState: DepartureState.past,
            ),
          ]),
        ],
        size: const Size(393, 1600),
      );

      routes.hold();
      await tester.tap(find.text('Yolculuğu tamamla').first);
      await tester.pump();

      expect(find.text('Yolculuğu tamamla'), findsOneWidget);
      expect(find.text('Yolculuğu yarıda bırak'), findsOneWidget);

      routes.release();
      await tester.pumpAndSettle();
    });
  });

  group('When the server will not end it', () {
    MyRoute running() => fakeMyRoute(
      trip: TripState.inProgress,
      startedAt: '2026-09-11T07:05:00Z',
      recurrence: Recurrence.once,
      departureDate: '2026-09-11',
      departureState: DepartureState.past,
    );

    Future<void> refuse(
      WidgetTester tester,
      String control,
      TripRefusal refusal,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[running()]),
        ],
      );
      routes.tripFailure = RmFailure.fromBackend(
        status: 409,
        code: RmErrorCode.conflict,
        reason: refusal.wire,
      );

      await tester.tap(find.text(control));
      await tester.pumpAndSettle();
    }

    /// CARRIES WEIGHT. A journey nobody started cannot be ended, and saying so
    /// must not end it on screen.
    testWidgets('trip_not_started leaves both commands alone', (
      WidgetTester tester,
    ) async {
      for (final String control in <String>[
        'Yolculuğu tamamla',
        'Yolculuğu yarıda bırak',
      ]) {
        await refuse(tester, control, TripRefusal.tripNotStarted);

        expect(find.text('Bu yolculuk henüz başlatılmamış.'), findsOneWidget);
        expect(find.text('Yolculuk: Başladı'), findsOneWidget, reason: control);
        expect(find.text('Yolculuğu tamamla'), findsOneWidget, reason: control);
      }
    });

    /// CARRIES WEIGHT. The reason names WHICH ending happened and nothing
    /// about when, so neither is drawn from it.
    testWidgets('a stale ending is re-read, never synthesised', (
      WidgetTester tester,
    ) async {
      await refuse(tester, 'Yolculuğu tamamla', TripRefusal.alreadyAborted);

      expect(find.text('Bu yolculuk zaten yarıda bırakılmış.'), findsOneWidget);
      expect(find.text('Yolculuk: Yarıda bırakıldı'), findsNothing);
      expect(routes.callCount, greaterThan(1));

      await refuse(
        tester,
        'Yolculuğu yarıda bırak',
        TripRefusal.alreadyCompleted,
      );

      expect(find.text('Bu yolculuk zaten tamamlanmış.'), findsOneWidget);
      expect(find.text('Yolculuk: Tamamlandı'), findsNothing);
      expect(routes.callCount, greaterThan(1));
    });

    testWidgets('an unknown reason falls to the generic seam', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<MyRoute>[running()]),
        ],
      );
      routes.tripFailure = const RmFailure.fromBackend(
        status: 409,
        code: RmErrorCode.conflict,
        reason: 'trip_already_started',
      );

      await tester.tap(find.text('Yolculuğu tamamla'));
      await tester.pumpAndSettle();

      // The row is untouched, and not one of the six sentences this build
      // owns is used for a reason it has never heard of. The app's existing
      // `conflict` copy is shown instead.
      expect(find.text('Yolculuk: Başladı'), findsOneWidget);
      for (final String owned in <String>[
        'Bu yolculuk zaten tamamlanmış.',
        'Bu yolculuk zaten yarıda bırakılmış.',
        'Bu yolculuk henüz başlatılmamış.',
        'Bu yolculuk henüz başlatılamaz.',
        'Bu rota artık başlatılamaz.',
        'Tekrarlayan rotalarda yolculuk başlatma henüz yok.',
      ]) {
        expect(find.text(owned), findsNothing, reason: owned);
      }
    });
  });
}
