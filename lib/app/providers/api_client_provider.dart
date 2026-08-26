import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/rm_api_client.dart';

/// The one HTTP client, supplied by whoever composed the app.
///
/// Override-only, exactly like [rmSessionProvider]. `RmApiClient.fromConfig()`
/// throws when the base URL was not compiled in, and widget tests never pass a
/// dart-define — so a provider that built one eagerly would take the whole
/// suite down at import time rather than at the one seam that needs it.
final Provider<RmApiClient> rmApiClientProvider = Provider<RmApiClient>(
  (Ref ref) => throw UnimplementedError(
    'rmApiClientProvider must be overridden — see main() and the tests.',
  ),
);
