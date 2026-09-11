// ─────────────────────────────────────────────────────────────
// RideMate — My Routes reads the server again when it is reopened
//
// THE DEFECT THIS FILE EXISTS FOR
//
// Found on a physical device. The provider lived for the whole process, so
// leaving My Routes kept the loaded page. A driver published a journey at 01:44
// and reopened My Routes, which still rendered the page read at 01:38 — their
// new route absent, with nothing to say why. The reasonable conclusion is that
// publishing failed.
//
// The tests below are written against OBSERVABLE BEHAVIOUR — how many times the
// repository is asked, and what the member ends up seeing — rather than against
// `isAutoDispose`. A future implementation that fixes staleness another way
// should keep these passing.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/routes/my_route.dart';
import 'package:ridemate/features/my_routes/application/my_routes_providers.dart';
import 'package:ridemate/features/my_routes/data/my_routes_repository.dart';
import 'package:ridemate/features/my_routes/domain/my_routes_page.dart';
import 'package:ridemate/features/my_routes/presentation/my_routes_screen.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/pump.dart';

void main() {
  setUpAll(loadRideMateFonts);

  MyRoutesResult page(List<String> ids) => MyRoutesResult(
    routes: <MyRoute>[
      for (final String id in ids) fakeMyRoute(id: id, originLabel: 'Yer $id'),
    ],
    nextCursor: null,
  );

  group('Reopening the screen asks the server again', () {
    /// CARRIES WEIGHT. This is the defect, reproduced through the real widget
    /// and navigation lifecycle rather than by poking the provider.
    ///
    /// The second read deliberately returns a route the first read could not
    /// have seen — exactly the physical-device sequence: open My Routes,
    /// publish elsewhere, reopen, and expect the new journey to be there.
    testWidgets('a route published after the first read appears on reopen', (
      WidgetTester tester,
    ) async {
      final FakeMyRoutesRepository routes = FakeMyRoutesRepository(
        pages: <MyRoutesResult>[
          page(<String>['a']),
        ],
      );

      await tester.pumpRm(
        const _MyRoutesHost(),
        surfaceSize: const Size(393, 852),
        overrides: <Override>[
          myRoutesRepositoryProvider.overrideWithValue(routes),
        ],
      );

      // Open My Routes for the first time.
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(routes.callCount, 1, reason: 'one entry, one read');
      expect(find.textContaining('Yer a'), findsOneWidget);
      expect(find.textContaining('Yer b'), findsNothing);

      // Leave the screen. Popped through the Navigator, which is exactly what
      // go_router's back control delegates to — the screen's own RmIconButton
      // calls `context.canPop()` and needs a GoRouter this host does not
      // provide. What matters here is that the route is popped and the widget
      // disposed, which is what releases the last listener.
      final NavigatorState navigator = tester.state<NavigatorState>(
        find.byType(Navigator).last,
      );
      navigator.pop();
      await tester.pumpAndSettle();

      // Something published while the list was closed — the server now holds a
      // route the first read never saw.
      routes.chain(<MyRoutesResult>[
        page(<String>['a', 'b']),
      ]);

      // Reopen.
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        routes.callCount,
        2,
        reason: 'reopening must ask the server again, not serve a stale page',
      );
      expect(
        find.textContaining('Yer b'),
        findsOneWidget,
        reason: 'the newly published route must be visible',
      );
      expect(find.textContaining('Yer a'), findsOneWidget);
    });

    testWidgets('staying on the screen does not re-read on rebuild', (
      WidgetTester tester,
    ) async {
      final FakeMyRoutesRepository routes = FakeMyRoutesRepository(
        pages: <MyRoutesResult>[
          page(<String>['a']),
        ],
      );

      await tester.pumpRm(
        const _MyRoutesHost(),
        surfaceSize: const Size(393, 852),
        overrides: <Override>[
          myRoutesRepositoryProvider.overrideWithValue(routes),
        ],
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(routes.callCount, 1);

      // Several frames while the screen stays mounted and observed.
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(
        routes.callCount,
        1,
        reason: 'a rebuild while still observed must not re-read',
      );
    });
  });

  group('Provider lifecycle, observed through the repository', () {
    /// Disposal is scheduled, not synchronous, so the test lets Riverpod's own
    /// lifecycle run instead of assuming the moment it happens.
    test(
      'a new subscription after the last one ends performs one new read',
      () async {
        final FakeMyRoutesRepository routes = FakeMyRoutesRepository(
          pages: <MyRoutesResult>[
            page(<String>['a']),
          ],
        );
        final ProviderContainer c = ProviderContainer(
          overrides: <Override>[
            myRoutesRepositoryProvider.overrideWithValue(routes),
          ],
        );
        addTearDown(c.dispose);

        final ProviderSubscription<AsyncValue<MyRoutesPage>> first = c
            .listen<AsyncValue<MyRoutesPage>>(
              myRoutesProvider,
              (AsyncValue<MyRoutesPage>? _, AsyncValue<MyRoutesPage> _) {},
              fireImmediately: true,
            );
        await c.read(myRoutesProvider.future);
        expect(routes.callCount, 1);

        // A second listener alongside the first changes nothing.
        final ProviderSubscription<AsyncValue<MyRoutesPage>> second = c
            .listen<AsyncValue<MyRoutesPage>>(
              myRoutesProvider,
              (AsyncValue<MyRoutesPage>? _, AsyncValue<MyRoutesPage> _) {},
              fireImmediately: true,
            );
        await pumpEventQueue();
        expect(routes.callCount, 1, reason: 'still observed — no new read');

        // Release every listener and let the scheduled disposal run.
        first.close();
        second.close();
        await pumpEventQueue();

        // The server has moved on in the meantime.
        routes.chain(<MyRoutesResult>[
          page(<String>['a', 'b']),
        ]);

        c.listen<AsyncValue<MyRoutesPage>>(
          myRoutesProvider,
          (AsyncValue<MyRoutesPage>? _, AsyncValue<MyRoutesPage> _) {},
          fireImmediately: true,
        );
        final MyRoutesPage reread = await c.read(myRoutesProvider.future);

        expect(routes.callCount, 2, reason: 'exactly one new read, not more');
        expect(
          <String>[for (final MyRoute r in reread.routes) r.id],
          <String>['a', 'b'],
          reason: 'the re-read must expose data the first read could not see',
        );
      },
    );

    /// The retry policy must survive the auto-dispose change: a failed read is
    /// still one request that stays failed until somebody asks again.
    test('noAutomaticRetry is still in force', () async {
      final FakeMyRoutesRepository routes = FakeMyRoutesRepository(
        failure: const RmFailure.transport(),
      );
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          myRoutesRepositoryProvider.overrideWithValue(routes),
        ],
      );
      addTearDown(c.dispose);

      c.listen<AsyncValue<MyRoutesPage>>(
        myRoutesProvider,
        (AsyncValue<MyRoutesPage>? _, AsyncValue<MyRoutesPage> _) {},
        fireImmediately: true,
      );
      await pumpEventQueue();

      expect(routes.callCount, 1);
      expect(c.read(myRoutesProvider).hasError, isTrue);

      // Riverpod's default would have retried on a backoff by now.
      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(
        routes.callCount,
        1,
        reason: 'a failed read must not retry itself',
      );
    });
  });
}

/// A host with a route to push, so the test exercises the real navigation
/// lifecycle — pushing and popping a screen — rather than mounting the widget
/// directly, which would never release the listener the way a pop does.
class _MyRoutesHost extends StatelessWidget {
  const _MyRoutesHost();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => const MyRoutesScreen(),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
}
