// ─────────────────────────────────────────────────────────────
// RideMate — where the session is reached from
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/rm_session.dart';

/// The session.
///
/// Deliberately has NO default, unlike the preference and credential
/// providers. Those can fall back to a harmless in-memory store; a session
/// cannot, because a default would need an HTTP client and a base URL, and the
/// only honest values for those reach the network. A test that forgets to
/// override this gets a clear failure instead of a silent request.
///
/// Overridden in `main()`, and in tests with a session over a fake transport.
final Provider<RmSession> rmSessionProvider = Provider<RmSession>(
  (Ref ref) => throw UnimplementedError(
    'rmSessionProvider must be overridden — see main() and the auth tests.',
  ),
);
