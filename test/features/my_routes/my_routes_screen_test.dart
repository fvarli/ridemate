import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/routes/ride_rule.dart';
import 'package:ridemate/core/widgets/rm_button.dart';
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
      ],
    );
    // Twice: the first frame is the loading state, the second the answer.
    await tester.pump();
    await tester.pump();
  }

  MyRoutesResult page(List<PublishedRoute> routes, {String? next}) =>
      MyRoutesResult(routes: routes, nextCursor: next);

  group('What the list shows', () {
    testWidgets('a published journey, as the server described it', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<PublishedRoute>[
            fakeRoute(
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
          page(<PublishedRoute>[fakeRoute(seatsOffered: 3)]),
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
          page(<PublishedRoute>[
            fakeRoute(
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
          page(<PublishedRoute>[
            fakeRoute(id: 'a', originLabel: 'Birinci'),
            fakeRoute(id: 'b', originLabel: 'İkinci'),
            fakeRoute(id: 'c', originLabel: 'Üçüncü'),
          ]),
        ],
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
          page(<PublishedRoute>[
            fakeRoute(
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
          page(<PublishedRoute>[fakeRoute(rules: const <RideRuleId>{})]),
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
          page(<PublishedRoute>[fakeRoute(rules: const <RideRuleId>{})]),
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
          page(<PublishedRoute>[
            fakeRoute(
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
          page(<PublishedRoute>[
            fakeRoute(
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
          page(<PublishedRoute>[
            fakeRoute(
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
          page(<PublishedRoute>[
            fakeRoute(
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
          page(<PublishedRoute>[fakeRoute(id: 'a')]),
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
          page(<PublishedRoute>[
            fakeRoute(id: 'a', originLabel: 'Birinci'),
            fakeRoute(id: 'b', originLabel: 'İkinci'),
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
          page(<PublishedRoute>[fakeRoute(id: 'a')]),
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
          page(<PublishedRoute>[fakeRoute(id: 'a')]),
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
          page(<PublishedRoute>[
            fakeRoute(id: 'a', originLabel: 'Birinci'),
            fakeRoute(id: 'b', originLabel: 'İkinci'),
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
          page(<PublishedRoute>[
            fakeRoute(id: 'a', originLabel: 'Birinci'),
            fakeRoute(id: 'b', originLabel: 'İkinci'),
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
          page(<PublishedRoute>[fakeRoute(id: 'a')], next: 'more'),
          page(<PublishedRoute>[fakeRoute(id: 'b', originLabel: 'İkinci')]),
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
          page(<PublishedRoute>[fakeRoute()]),
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
          page(<PublishedRoute>[
            fakeRoute(id: 'a', originLabel: 'Birinci'),
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
          page(<PublishedRoute>[fakeRoute(id: 'a')], next: 'more'),
          page(<PublishedRoute>[fakeRoute(id: 'b')]),
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
      await pump(tester, pages: <MyRoutesResult>[page(<PublishedRoute>[])]);

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
          page(<PublishedRoute>[fakeRoute(originLabel: 'Gerçek')]),
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
          page(<PublishedRoute>[
            fakeRoute(
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
        'Yolculuk',
        'uyum',
        'dk yürüme',
        'Selin',
      ]) {
        expect(find.textContaining(forbidden), findsNothing, reason: forbidden);
      }
    });

    /// The payload carries a timezone. The screen has no use for one, and
    /// drawing it would invite someone to compute with it.
    testWidgets('the timezone is decoded but never drawn', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<PublishedRoute>[fakeRoute()]),
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
          page(<PublishedRoute>[
            fakeRoute(
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

      handle.dispose();
    });

    testWidgets('renders in English, RTL and at the narrow width', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        pages: <MyRoutesResult>[
          page(<PublishedRoute>[
            fakeRoute(
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
}
