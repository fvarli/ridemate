// ─────────────────────────────────────────────────────────────
// RideMate — The account boundary
//
// What one member leaves behind in app-scoped state must be gone before the
// next member can see it or act on it — however the first one's session ended,
// and even if one of their requests was still out when it did.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/account_boundary.dart';
import 'package:ridemate/app/providers/session_provider.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/places/place.dart';
import 'package:ridemate/core/routes/departure.dart';
import 'package:ridemate/core/session/rm_session.dart';
import 'package:ridemate/features/create_route/application/create_route_providers.dart';
import 'package:ridemate/features/create_route/application/publication_providers.dart';
import 'package:ridemate/features/create_route/domain/create_route_fixtures.dart';
import 'package:ridemate/features/discovery/application/discovery_providers.dart';
import 'package:ridemate/features/discovery/application/discovery_search_providers.dart';
import 'package:ridemate/features/discovery/domain/search_draft.dart';

import '../support/fakes.dart';

void main() {
  const Place home = Place(
    id: '01991a00-0000-7000-8000-00000000000a',
    label: 'Sunucu Yeri A',
  );
  const Place work = Place(
    id: '01991a00-0000-7000-8000-00000000000b',
    label: 'Sunucu Yeri B',
  );

  late FakeSession session;
  late FakeRouteRepository routes;
  late FakeUuidGenerator ids;

  ProviderContainer container() {
    session = FakeSession();
    routes = FakeRouteRepository();
    ids = FakeUuidGenerator();

    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        rmSessionProvider.overrideWithValue(session),
        routeRepositoryProvider.overrideWithValue(routes),
        uuidGeneratorProvider.overrideWithValue(ids),
      ],
    );
    addTearDown(c.dispose);

    // Installed the way the router installs it.
    c.read(accountBoundaryProvider);

    // Kept alive the way the mounted screens keep them alive, so a reset is a
    // rebuild the test can observe rather than a disposal it cannot.
    c
      ..listen(createRouteDraftProvider, (_, _) {})
      ..listen(publicationProvider, (_, _) {})
      ..listen(searchDraftProvider, (_, _) {})
      ..listen(discoveryQueryProvider, (_, _) {});

    return c;
  }

  /// Member A: a route half-composed, a search in effect, and a publication
  /// whose outcome was never learned — so its id is waiting to be reused.
  Future<String> leaveStateBehind(ProviderContainer c) async {
    final CreateRouteDraftController draft = c.read(
      createRouteDraftProvider.notifier,
    );
    draft
      ..setOrigin(home)
      ..setDestination(work)
      ..setDepartureTime(const DepartureTime(hour: 7, minute: 40));

    c.read(searchDraftProvider.notifier)
      ..setOrigin(work)
      ..setDestination(home);
    c
        .read(discoveryQueryProvider.notifier)
        .search(
          DiscoveryQuery(originPlaceId: work.id, destinationPlaceId: home.id),
        );

    routes.failure = const RmFailure.transport();
    await c.read(publicationProvider.notifier).publish();
    routes.failure = null;

    expect(c.read(publicationProvider), isA<PublicationRetryable>());
    final String? pending = c.read(publicationProvider.notifier).pendingRouteId;
    expect(pending, isNotNull);

    return pending!;
  }

  void expectFresh(ProviderContainer c) {
    expect(c.read(createRouteDraftProvider), kInitialCreateRouteDraft);
    expect(c.read(publicationProvider), isA<PublicationIdle>());
    expect(c.read(publicationProvider.notifier).pendingRouteId, isNull);
    expect(c.read(searchDraftProvider), const SearchDraft());
    expect(c.read(discoveryQueryProvider), isNull);
  }

  /// Every way a session ends is a boundary, not only the button. Any of them
  /// can be followed by somebody else signing in on the same device.
  group('Any transition to signed out resets member state', () {
    final Map<String, void Function(FakeSession)> endings =
        <String, void Function(FakeSession)>{
          'an explicit sign-out': (FakeSession s) => s.signOut(),
          'a session that ended': (FakeSession s) =>
              s.endSession(RmSignedOutReason.sessionEnded),
          'a suspended account': (FakeSession s) =>
              s.endSession(RmSignedOutReason.accountSuspended),
          'a sign-out with no reason at all': (FakeSession s) =>
              s.become(const RmSignedOut()),
        };

    for (final MapEntry<String, void Function(FakeSession)> ending
        in endings.entries) {
      test(ending.key, () async {
        final ProviderContainer c = container();
        await leaveStateBehind(c);

        ending.value(session);

        expectFresh(c);
      });
    }
  });

  /// Theme, language and the intro flag belong to the device. Nothing here
  /// touches them, and a signed-in session is not a boundary.
  test('staying signed in resets nothing', () async {
    final ProviderContainer c = container();
    await leaveStateBehind(c);

    session.become(const RmSignedIn('SESSION_ROTATED'));

    expect(c.read(createRouteDraftProvider).origin, home);
    expect(c.read(discoveryQueryProvider), isNotNull);
    expect(c.read(publicationProvider), isA<PublicationRetryable>());
  });

  test(
    'member B starts from nothing, and publishes under a fresh id',
    () async {
      final ProviderContainer c = container();
      final String aPending = await leaveStateBehind(c);

      await session.signOut();
      await session.verifyPasscode(phone: '+905329876543', code: '123456');

      expectFresh(c);

      c.read(createRouteDraftProvider.notifier)
        ..setOrigin(work)
        ..setDestination(home)
        ..setDepartureTime(const DepartureTime(hour: 9, minute: 0));
      await c.read(publicationProvider.notifier).publish();

      expect(c.read(publicationProvider), isA<PublicationConfirmed>());
      expect(routes.routeIds.last, isNot(aPending));
      expect(routes.routeIds.last, ids.minted.last);
      expect(routes.commands.last.draft.departureTime?.hour, 9);
    },
  );

  /// A request that was out when A left must not write A's answer into the
  /// state B is about to see — whether it answers yes or not.
  group('A late answer from A writes nothing', () {
    for (final bool succeeds in <bool>[true, false]) {
      test(succeeds ? 'a success' : 'a failure', () async {
        final ProviderContainer c = container();
        await leaveStateBehind(c);
        final String aPending = c
            .read(publicationProvider.notifier)
            .pendingRouteId!;

        routes.hold();
        if (!succeeds) routes.failure = const RmFailure.transport();
        final Future<void> inFlight = c
            .read(publicationProvider.notifier)
            .publish();
        expect(c.read(publicationProvider), isA<PublicationInFlight>());

        await session.signOut();
        await session.verifyPasscode(phone: '+905329876543', code: '123456');

        // B is already looking at a fresh screen when A's answer arrives —
        // the order that matters, because it is the rebuilt state a late
        // write would land in.
        expectFresh(c);

        routes.release();
        // Completes normally: the stale controller notices it was replaced
        // rather than throwing at a disposed ref.
        await inFlight;
        routes.failure = null;

        expectFresh(c);

        // And B's first publication is B's own attempt.
        c.read(createRouteDraftProvider.notifier)
          ..setOrigin(home)
          ..setDestination(work)
          ..setDepartureTime(const DepartureTime(hour: 8, minute: 0));
        await c.read(publicationProvider.notifier).publish();

        expect(routes.routeIds.last, isNot(aPending));
        expect(c.read(publicationProvider), isA<PublicationConfirmed>());
      });
    }
  });
}
