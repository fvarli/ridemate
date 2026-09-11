import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/routes/my_route.dart';
import 'package:ridemate/core/routes/published_route.dart';
import 'package:ridemate/core/trips/trip_lifecycle.dart';
import 'package:ridemate/core/widgets/rm_list_row.dart';
import 'package:ridemate/features/my_routes/application/my_routes_providers.dart';
import 'package:ridemate/features/my_routes/data/my_routes_repository.dart';
import 'package:ridemate/features/my_routes/presentation/trip_status_screen.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/pump.dart';

/// One journey's lifecycle, in full.
///
/// Mostly about what this screen does NOT say. It replaces nothing — the Active
/// Trip fixture stays where it is — and it exists because a card has no room
/// for three timestamps, not because a driver needs a richer picture than the
/// backend has.
void main() {
  setUpAll(loadRideMateFonts);

  const String kId = '01991b00-0000-7000-8000-000000000001';

  late FakeMyRoutesRepository routes;

  Future<void> pump(
    WidgetTester tester, {
    required List<MyRoute> rows,
    String routeId = kId,
    RmFailure? failure,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    routes = FakeMyRoutesRepository(
      pages: <MyRoutesResult>[MyRoutesResult(routes: rows, nextCursor: null)],
      failure: failure,
    );

    await tester.pumpRm(
      TripStatusScreen(routeId: routeId),
      textDirection: textDirection,
      surfaceSize: const Size(393, 900),
      overrides: <Override>[
        myRoutesRepositoryProvider.overrideWithValue(routes),
      ],
    );
    await tester.pump();
    await tester.pump();
  }

  MyRoute row({
    TripState trip = TripState.notStarted,
    String? startedAt,
    String? completedAt,
    String? abortedAt,
  }) => fakeMyRoute(
    id: kId,
    originLabel: 'Kadıköy, Vapur İskelesi',
    destinationLabel: 'Levent, Metro İstasyonu',
    recurrence: Recurrence.once,
    departureDate: '2026-09-11',
    departureTime: '08:25',
    departureState: DepartureState.past,
    trip: trip,
    startedAt: startedAt,
    completedAt: completedAt,
    abortedAt: abortedAt,
  );

  group('What it says', () {
    testWidgets('the journey, the departure and the state', (
      WidgetTester tester,
    ) async {
      await pump(tester, rows: <MyRoute>[row()]);

      expect(
        find.text('Kadıköy, Vapur İskelesi → Levent, Metro İstasyonu'),
        findsOneWidget,
      );
      expect(find.text('Planlanan kalkış'), findsOneWidget);
      expect(find.text('2026-09-11 · 08:25'), findsOneWidget);
      expect(find.text('Başlamadı'), findsOneWidget);
    });

    testWidgets('each of the four states, and no wire string', (
      WidgetTester tester,
    ) async {
      for (final (TripState state, String copy) in <(TripState, String)>[
        (TripState.notStarted, 'Başlamadı'),
        (TripState.inProgress, 'Başladı'),
        (TripState.completed, 'Tamamlandı'),
        (TripState.aborted, 'Yarıda bırakıldı'),
      ]) {
        await pump(
          tester,
          rows: <MyRoute>[
            row(
              trip: state,
              startedAt: state == TripState.notStarted
                  ? null
                  : '2026-09-11T07:05:00Z',
              completedAt: state == TripState.completed
                  ? '2026-09-11T07:45:00Z'
                  : null,
              abortedAt: state == TripState.aborted
                  ? '2026-09-11T07:20:00Z'
                  : null,
            ),
          ],
        );

        expect(find.text(copy), findsWidgets, reason: state.wire);
        expect(
          find.textContaining(state.wire),
          findsNothing,
          reason: state.wire,
        );
      }
    });

    /// CARRIES WEIGHT. `in_progress` says one thing, and the screen says which.
    testWidgets('a started journey says what starting does not mean', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        rows: <MyRoute>[
          row(trip: TripState.inProgress, startedAt: '2026-09-11T07:05:00Z'),
        ],
      );

      expect(find.textContaining('RideMate\'te başlattığını'), findsOneWidget);
    });
  });

  group('Timestamps', () {
    /// CARRIES WEIGHT. A row exists because the server sent that instant.
    testWidgets('an unstarted journey shows none of the three', (
      WidgetTester tester,
    ) async {
      await pump(tester, rows: <MyRoute>[row()]);

      expect(find.text('Başlangıç'), findsNothing);
      expect(find.text('Tamamlanma'), findsNothing);
      expect(find.text('Yarıda bırakılma'), findsNothing);
    });

    testWidgets('a running journey shows only its beginning', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        rows: <MyRoute>[
          row(trip: TripState.inProgress, startedAt: '2026-09-11T07:05:00Z'),
        ],
      );

      expect(find.text('Başlangıç'), findsOneWidget);
      expect(find.text('Yarıda bırakılma'), findsNothing);
    });

    /// The right instant lands in the right row: two different times, and
    /// swapping them would show the wrong one under the wrong label.
    testWidgets('a finished journey shows both, each under its own label', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        rows: <MyRoute>[
          row(
            trip: TripState.completed,
            startedAt: '2026-09-11T07:05:00Z',
            completedAt: '2026-09-11T09:45:00Z',
          ),
        ],
      );

      final String started = _instantOf(tester, 'Başlangıç');
      final String completed = _instantOf(tester, 'Tamamlanma');

      expect(started, isNot(completed));
      expect(started, contains(_localHm('2026-09-11T07:05:00Z')));
      expect(completed, contains(_localHm('2026-09-11T09:45:00Z')));
    });

    /// CARRIES WEIGHT. Nothing is measured between the two instants.
    testWidgets('no duration, arrival, estimate or elapsed time', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        rows: <MyRoute>[
          row(
            trip: TripState.completed,
            startedAt: '2026-09-11T07:05:00Z',
            completedAt: '2026-09-11T09:45:00Z',
          ),
        ],
      );

      for (final String absent in <String>[
        'Süre',
        'dk',
        'saat sürdü',
        'Varış',
        'Tahmini',
        'km',
        'Geçen',
      ]) {
        expect(find.textContaining(absent), findsNothing, reason: absent);
      }
    });
  });

  group('Nothing the backend does not know', () {
    testWidgets('no map, location, navigation, chat, SOS or passenger', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        rows: <MyRoute>[
          row(trip: TripState.inProgress, startedAt: '2026-09-11T07:05:00Z'),
        ],
      );

      for (final String absent in <String>[
        'Harita',
        'Navigasyon',
        'Yol tarifi',
        'SOS',
        'Acil',
        'Mesaj',
        'Ara',
        'Konumu paylaş',
        'Yolcu bindi',
        'Puan',
        'Değerlendir',
        '₺',
      ]) {
        expect(find.textContaining(absent), findsNothing, reason: absent);
      }
    });
  });

  group('Acting from here', () {
    testWidgets('an unstarted journey offers Start alone', (
      WidgetTester tester,
    ) async {
      await pump(tester, rows: <MyRoute>[row()]);

      expect(find.text('Yolculuğu başlat'), findsOneWidget);
      expect(find.text('Yolculuğu tamamla'), findsNothing);
      expect(find.text('Yolculuğu yarıda bırak'), findsNothing);
    });

    testWidgets('a running journey offers both endings', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        rows: <MyRoute>[
          row(trip: TripState.inProgress, startedAt: '2026-09-11T07:05:00Z'),
        ],
      );

      expect(find.text('Yolculuğu başlat'), findsNothing);
      expect(find.text('Yolculuğu tamamla'), findsOneWidget);
      expect(find.text('Yolculuğu yarıda bırak'), findsOneWidget);
    });

    testWidgets('a terminal journey offers nothing', (
      WidgetTester tester,
    ) async {
      for (final TripState state in <TripState>[
        TripState.completed,
        TripState.aborted,
      ]) {
        await pump(
          tester,
          rows: <MyRoute>[
            row(
              trip: state,
              startedAt: '2026-09-11T07:05:00Z',
              completedAt: state == TripState.completed
                  ? '2026-09-11T07:45:00Z'
                  : null,
              abortedAt: state == TripState.aborted
                  ? '2026-09-11T07:20:00Z'
                  : null,
            ),
          ],
        );

        for (final String control in <String>[
          'Yolculuğu başlat',
          'Yolculuğu tamamla',
          'Yolculuğu yarıda bırak',
        ]) {
          expect(find.text(control), findsNothing, reason: state.wire);
        }
      }
    });

    testWidgets('completing here sends this journey and renders the answer', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        rows: <MyRoute>[
          row(trip: TripState.inProgress, startedAt: '2026-09-11T07:05:00Z'),
        ],
      );

      await tester.tap(find.text('Yolculuğu tamamla'));
      await tester.pumpAndSettle();

      expect(routes.tripCommands, <String>['complete $kId']);
      expect(find.text('Tamamlandı'), findsWidgets);
    });

    testWidgets('a refusal says so and moves nothing', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        rows: <MyRoute>[
          row(trip: TripState.inProgress, startedAt: '2026-09-11T07:05:00Z'),
        ],
      );
      routes.tripFailure = const RmFailure.fromBackend(
        status: 409,
        code: RmErrorCode.conflict,
        reason: 'trip_not_started',
      );

      await tester.tap(find.text('Yolculuğu yarıda bırak'));
      await tester.pumpAndSettle();

      expect(find.text('Bu yolculuk henüz başlatılmamış.'), findsOneWidget);
      expect(find.text('Başladı'), findsWidgets);
      expect(find.text('Yolculuğu tamamla'), findsOneWidget);
    });
  });

  group('When there is no such row', () {
    /// CARRIES WEIGHT. There is no endpoint that reads one owned route, so a
    /// row outside the loaded pages is absent rather than fetchable — and
    /// absence is said, never filled in.
    testWidgets('a journey not in the list says so and invents nothing', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        rows: <MyRoute>[row()],
        routeId: '01991b00-0000-7000-8000-0000000000ff',
      );

      expect(find.text('Bu rota listende yok'), findsOneWidget);
      expect(find.text('Başlamadı'), findsNothing);
      expect(find.text('Yolculuğu başlat'), findsNothing);
      expect(find.text('Yeniden dene'), findsOneWidget);
    });

    testWidgets('a failed read is stated, not drawn as an empty journey', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        rows: <MyRoute>[row()],
        failure: const RmFailure.transport(),
      );

      expect(find.text('Başlamadı'), findsNothing);
      expect(find.text('Yeniden dene'), findsOneWidget);
    });
  });

  group('Direction', () {
    testWidgets('it renders right-to-left without overflow', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        rows: <MyRoute>[
          row(
            trip: TripState.completed,
            startedAt: '2026-09-11T07:05:00Z',
            completedAt: '2026-09-11T09:45:00Z',
          ),
        ],
        textDirection: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Tamamlandı'), findsWidgets);
    });
  });
}

/// The instant rendered in the row titled [label].
String _instantOf(WidgetTester tester, String label) {
  for (final RmListRow row in tester.widgetList<RmListRow>(
    find.byType(RmListRow),
  )) {
    if (row.title == label) {
      final String? subtitle = row.subtitle;
      if (subtitle != null) return subtitle;
    }
  }

  fail('no instant rendered under "$label"');
}

/// The wall clock a reader in this test's zone sees for [iso].
String _localHm(String iso) {
  final DateTime local = DateTime.parse(iso).toLocal();

  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
