import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/config/rm_api_config.dart';

/// The configuration rules, exercised through [RmApiConfig.normalize].
///
/// [String.fromEnvironment] resolves at compile time, so the compiled-in value
/// cannot be varied from a test. That is precisely why the validation lives in
/// a pure function taking a string: every rule is reachable here, and the
/// getter is left doing nothing but supplying the argument.
void main() {
  group('accepts the URLs local development actually uses', () {
    test('the Android emulator host', () {
      expect(
        RmApiConfig.normalize('http://10.0.2.2:8000'),
        'http://10.0.2.2:8000',
      );
    });

    test('a physical device through adb reverse', () {
      expect(
        RmApiConfig.normalize('http://127.0.0.1:8000'),
        'http://127.0.0.1:8000',
      );
    });

    test('localhost', () {
      expect(
        RmApiConfig.normalize('http://localhost:8000'),
        'http://localhost:8000',
      );
    });

    test('https, for whatever the deployed backend turns out to be', () {
      expect(
        RmApiConfig.normalize('https://api.example.test'),
        'https://api.example.test',
      );
    });

    test('surrounding whitespace, which a copied command tends to carry', () {
      expect(
        RmApiConfig.normalize('  http://10.0.2.2:8000  '),
        'http://10.0.2.2:8000',
      );
    });
  });

  group('normalizes exactly one thing', () {
    test('a trailing slash is removed', () {
      expect(
        RmApiConfig.normalize('http://127.0.0.1:8000/'),
        'http://127.0.0.1:8000',
      );
      expect(
        RmApiConfig.normalize('https://api.example.test/'),
        'https://api.example.test',
      );
    });

    test('a value without one is returned unchanged', () {
      expect(
        RmApiConfig.normalize('https://api.example.test'),
        'https://api.example.test',
      );
    });

    /// The reason the rule is "remove a trailing slash" and not "remove the
    /// path": a backend mounted under a prefix is a real deployment, and
    /// discarding it would point the app at the wrong place while looking
    /// like it worked.
    test('a meaningful path survives', () {
      expect(
        RmApiConfig.normalize('https://api.example.test/ridemate/'),
        'https://api.example.test/ridemate',
      );
    });

    test('the port survives', () {
      expect(
        RmApiConfig.normalize('https://api.example.test:8443/'),
        'https://api.example.test:8443',
      );
    });
  });

  group('refuses anything it would have to guess about', () {
    /// Nothing below is repaired. A missing scheme is not assumed to be
    /// https, and a typo is not corrected: a configuration that silently
    /// became something other than what was written fails later, somewhere
    /// else, and much more confusingly.
    for (final (String label, String value) in <(String, String)>[
      ('empty', ''),
      ('a single space', ' '),
      ('only whitespace', '   \t  '),
      ('no scheme', '10.0.2.2:8000'),
      ('scheme-relative', '//10.0.2.2:8000'),
      ('a bare host', 'localhost'),
      ('a path only', '/api/v1'),
      ('no host', 'http://'),
      ('ftp', 'ftp://files.example.test'),
      ('websockets', 'ws://10.0.2.2:8000'),
      ('a file URL', 'file:///etc/hosts'),
      ('a query string', 'http://10.0.2.2:8000?token=x'),
      ('a fragment', 'http://10.0.2.2:8000#top'),
      ('spaces inside', 'http://10.0.2.2 :8000'),
    ]) {
      test(label, () {
        expect(
          () => RmApiConfig.normalize(value),
          throwsA(isA<RmConfigurationError>()),
        );
      });
    }
  });

  group('the failure explains itself', () {
    test('it names the variable and shows the command to run', () {
      final String message = _messageFor('');

      expect(message, contains(RmApiConfig.variable));
      expect(message, contains('--dart-define'));
      expect(message, contains('10.0.2.2:8000'));
      expect(message, contains('adb reverse'));
    });

    test('it distinguishes unset from blank', () {
      expect(_messageFor(''), contains('is not set'));
      expect(_messageFor('   '), contains('whitespace'));
    });

    test('it names the offending scheme', () {
      expect(_messageFor('ftp://files.example.test'), contains('ftp'));
    });

    /// The message is printed to a console and pasted into issues, so it must
    /// not carry anything a developer would then have to redact.
    test('it does not echo the configured value', () {
      expect(
        _messageFor('ftp://secret-host.internal'),
        isNot(contains('secret-host')),
      );
    });
  });

  group('the compile-time seam', () {
    /// Nothing throws while the class is initialised. The suite never passes
    /// the define, so a class that failed at import would take every
    /// unrelated test down with it.
    test('touching the class does not throw', () {
      expect(RmApiConfig.variable, 'RIDEMATE_API_BASE_URL');
      expect(RmApiConfig.allowedSchemes, <String>{'http', 'https'});
    });

    /// And with no define supplied — which is exactly how tests run — asking
    /// for the value fails rather than inventing one.
    test('an unconfigured build refuses to produce a base URL', () {
      expect(() => RmApiConfig.baseUrl, throwsA(isA<RmConfigurationError>()));
      expect(RmApiConfig.verify, throwsA(isA<RmConfigurationError>()));
    });
  });
}

String _messageFor(String value) {
  try {
    RmApiConfig.normalize(value);
  } on RmConfigurationError catch (error) {
    return error.toString();
  }

  fail('"$value" should have been refused');
}
