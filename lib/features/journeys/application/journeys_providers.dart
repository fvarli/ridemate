// ─────────────────────────────────────────────────────────────
// RideMate — Dated journey access
//
// A REPOSITORY, AND NO STATE MACHINERY YET
//
// The reads and the three dated commands are wired; nothing watches them. A
// controller invented here would be a state machine maintained on the chance a
// screen someday wants one, and which screen — and what it shows — is F2's
// decision rather than this slice's.
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/api_client_provider.dart';
import '../../../app/providers/session_provider.dart';
import '../data/journeys_repository.dart';

final Provider<JourneysRepository> journeysRepositoryProvider =
    Provider<JourneysRepository>(
      (Ref ref) => ApiJourneysRepository(
        client: ref.watch(rmApiClientProvider),
        session: ref.watch(rmSessionProvider),
      ),
    );
