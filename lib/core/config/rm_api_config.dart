// ─────────────────────────────────────────────────────────────
// RideMate — API configuration
//
// Where the backend lives, decided at BUILD time and nowhere else.
//
// This is the whole configuration system, and it is one string on purpose.
// The alternatives were considered and each buys a problem: flavors multiply
// build variants before there is a second environment to build for; a bundled
// .env or JSON file ships the answer inside the artifact where it can be read
// and cannot be changed; a config package adds a dependency to hold a value
// that never changes after compilation.
//
// A --dart-define is compiled in, absent from the source tree, and different
// per build without any of that machinery.
// ─────────────────────────────────────────────────────────────

/// Configuration that is wrong or missing, discovered at startup.
///
/// An [Error] rather than an [Exception], deliberately. An exception is a
/// runtime condition worth handling; this is a build that was assembled
/// incorrectly, and no amount of retrying or catching improves it. The only
/// useful response is to fix the command and build again, so the message says
/// exactly what to type.
final class RmConfigurationError extends Error {
  RmConfigurationError(this.reason);

  final String reason;

  @override
  String toString() =>
      'RideMate is not configured correctly.\n'
      '\n'
      '$reason\n'
      '\n'
      'Supply the backend URL at build time:\n'
      '\n'
      '  # Android emulator\n'
      '  flutter run --dart-define=${RmApiConfig.variable}=http://10.0.2.2:8000\n'
      '\n'
      '  # Physical Android device\n'
      '  adb reverse tcp:8000 tcp:8000\n'
      '  flutter run --dart-define=${RmApiConfig.variable}=http://127.0.0.1:8000\n';
}

/// The backend base URL, and the rules it has to satisfy.
abstract final class RmApiConfig {
  const RmApiConfig._();

  /// The name of the compile-time define. Referenced in the failure message
  /// so the two can never drift apart.
  static const String variable = 'RIDEMATE_API_BASE_URL';

  /// Both, and not HTTPS-only.
  ///
  /// Requiring HTTPS everywhere would be the obvious rule and would make local
  /// Android development impossible: the emulator reaches the host over plain
  /// HTTP at 10.0.2.2, and a physical device does the same through
  /// `adb reverse`. Cleartext is confined instead by the Android network
  /// security configuration, which permits it for three local hosts in DEBUG
  /// BUILDS ONLY. Release keeps no exception of any kind.
  static const Set<String> allowedSchemes = <String>{'http', 'https'};

  /// Compiled in. Empty when nobody passed the define.
  ///
  /// `const`, so nothing here can throw at import time. That matters: the test
  /// suite never passes the define, and a class that failed while being
  /// initialised would take every unrelated test down with it. Only [baseUrl]
  /// and [verify] can fail, and only when something actually asks.
  static const String _configured = String.fromEnvironment(
    variable,
    defaultValue: '',
  );

  /// The configured backend URL, without a trailing slash.
  ///
  /// Throws [RmConfigurationError] if the build was not configured.
  static String get baseUrl => normalize(_configured);

  /// Fails now, loudly, rather than at the first request.
  ///
  /// Called from the bootstrap. A misconfigured build that started normally
  /// would look healthy until a member tried to sign in, and the failure would
  /// then arrive as a network error — describing the symptom and not the cause.
  static void verify() {
    normalize(_configured);
  }

  /// Validates and canonicalises a configured value.
  ///
  /// Separate from [baseUrl] because [String.fromEnvironment] resolves at
  /// compile time and cannot be varied from a test. Every rule below is
  /// therefore exercised by calling this directly; the getter only supplies
  /// the compiled-in argument.
  ///
  /// Nothing here repairs a bad value. A missing scheme is not assumed to be
  /// https, and a typo is not corrected — a configuration that silently became
  /// something other than what was written is worse than one that refuses to
  /// start, because it fails later and somewhere else.
  static String normalize(String value) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      throw RmConfigurationError(
        value.isEmpty
            ? '$variable is not set.'
            : '$variable contains only whitespace.',
      );
    }

    // Checked before Uri.tryParse, because that parser is more forgiving than
    // it looks: `http://10.0.2.2 :8000` comes back as a Uri with a plausible
    // scheme and host, passes every structural rule below, and only falls over
    // later when something tries to make a request with it. A URL cannot
    // contain unencoded whitespace, so this is a syntax error rather than a
    // judgement call.
    if (trimmed.contains(RegExp(r'\s'))) {
      throw RmConfigurationError('$variable contains whitespace.');
    }

    final Uri? uri = Uri.tryParse(trimmed);

    if (uri == null) {
      throw RmConfigurationError('$variable is not a valid URL.');
    }

    if (!uri.hasScheme) {
      throw RmConfigurationError(
        '$variable has no scheme. Write it in full, for example '
        'http://10.0.2.2:8000 rather than 10.0.2.2:8000.',
      );
    }

    if (!allowedSchemes.contains(uri.scheme)) {
      throw RmConfigurationError(
        '$variable uses the "${uri.scheme}" scheme. '
        'Only ${allowedSchemes.join(' and ')} are supported.',
      );
    }

    if (uri.host.isEmpty) {
      throw RmConfigurationError('$variable has no host.');
    }

    // A base URL is something paths get appended to. Appending to a value
    // carrying a query or a fragment produces a URL nobody wrote and nobody
    // meant, so it is refused here rather than discovered later.
    if (uri.hasQuery || uri.hasFragment) {
      throw RmConfigurationError(
        '$variable must be a base URL, without a query string or fragment.',
      );
    }

    // The only change made to a valid value. Later code appends paths that
    // begin with a slash, and without this every request would carry a
    // doubled one.
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}
