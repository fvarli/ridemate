import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/api_client_provider.dart';
import '../../../app/providers/session_provider.dart';
import '../../../core/api/rm_retry.dart';
import '../../../core/places/place.dart';
import '../data/place_repository.dart';

/// The repository Create Route reads its endpoints from.
///
/// Deliberately feature-local. Search still chooses from fixtures, and giving
/// the two screens one shared place source would make it easy to point the
/// fixture one at the server — or, far worse, the server one at the fixtures —
/// without anybody deciding to.
final Provider<PlaceRepository> placeRepositoryProvider =
    Provider<PlaceRepository>(
      (Ref ref) => ApiPlaceRepository(
        client: ref.watch(rmApiClientProvider),
        session: ref.watch(rmSessionProvider),
      ),
    );

/// The catalogue, loaded when Create Route first asks for it.
///
/// An AsyncNotifier because the screen genuinely has four answers to render —
/// loading, a catalogue, an empty catalogue and a failure — and AsyncValue is
/// the shape this codebase already uses for exactly that (see
/// OnboardingController).
///
/// There is no cache and nothing is persisted: a retry asks the server again.
///
/// AUTO-DISPOSE, BECAUSE A CACHED CATALOGUE OUTLIVES THE SERVER'S CONFIRMATION
///
/// This provider used to live for the whole process. Leaving Create Route kept
/// the loaded catalogue, so re-entering the screen served places the server was
/// no longer confirming — and with the backend unreachable the screen showed no
/// failure at all: the previous endpoints still rendered, the picker still
/// opened, and a member could work their way towards a publication that could
/// not succeed. Found on a physical device, with the tunnel deliberately
/// removed and `GET /places` never attempted.
///
/// A screen whose whole purpose is to choose server-owned endpoints must not
/// present a list the server has not just confirmed. Auto-disposing fixes it at
/// the only place that owns the problem: the screen's `ref.watch` is the last
/// listener, so popping the screen tears the provider down and the next entry
/// reads the server again — or fails honestly, with Retry, when it cannot.
///
/// Within one visit the catalogue stays cached, which is correct: the picker
/// must not re-ask on every rebuild. This deliberately changes nothing while
/// the member remains on the screen.
///
/// `retry` is stated, not left to the default. Riverpod would otherwise retry a
/// failed catalogue ten times on a backoff — eleven requests, thirty-eight
/// seconds, none of them asked for, all of them aimed at a backend that has
/// just failed. See [noAutomaticRetry].
final AsyncNotifierProvider<PlaceCatalogueController, List<Place>>
placeCatalogueProvider =
    AsyncNotifierProvider<PlaceCatalogueController, List<Place>>(
      PlaceCatalogueController.new,
      isAutoDispose: true,
      retry: noAutomaticRetry,
    );

class PlaceCatalogueController extends AsyncNotifier<List<Place>> {
  @override
  Future<List<Place>> build() => ref.watch(placeRepositoryProvider).catalogue();

  /// Asks again, from scratch.
  ///
  /// `invalidateSelf` rather than assigning state by hand. Re-running build is
  /// what produces the loading state, the request and the new answer as one
  /// step — and assigning `state` after a FAILED build re-initialises the
  /// notifier as well, which sent two requests for one tap. A retry that
  /// quietly doubles the load on a server that just failed is the last thing
  /// a retry should do.
  void refresh() => ref.invalidateSelf();
}
