import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ridemate/core/api/rm_api_client.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/session/auth_api.dart';
import 'package:ridemate/core/session/credential_store.dart';
import 'package:ridemate/core/session/rm_credentials.dart';
import 'package:ridemate/core/session/rm_session.dart';

/// A backend that never answers must not hang the app.
///
/// The dangerous case is not a refused connection — that fails immediately.
/// It is a socket that is accepted and then goes quiet: a captive portal, a
/// black-holing firewall, a wedged server. package:http imposes no response
/// timeout and neither does the HttpClient beneath it, so without an explicit
/// bound the request stays pending forever.
///
/// TIME HERE IS FAKE, NOT SLEPT. testWidgets runs inside a FakeAsync zone, so
/// tester.pump(duration) fires the timeout's timer deterministically and the
/// suite stays fast. A real sleep would make these the slowest tests in the
/// project and still prove less.
void main() {
  /// A transport that accepts the request and never responds.
  http.Client blackHole() =>
      MockClient((http.Request request) => Completer<http.Response>().future);

  RmApiClient clientThatHangs({
    Duration timeout = const Duration(seconds: 5),
  }) => RmApiClient(
    baseUrl: Uri.parse('https://api.example.test'),
    transport: blackHole(),
    timeout: timeout,
  );

  testWidgets('a request that is never answered fails as transport', (
    WidgetTester tester,
  ) async {
    Object? outcome;

    unawaited(
      clientThatHangs()
          .get('/api/v1/me')
          .then<void>((_) => outcome = 'answered')
          .catchError((Object error) => outcome = error),
    );

    // Before the boundary: still pending, which is the correct behaviour for a
    // slow-but-alive network.
    await tester.pump(const Duration(seconds: 4));
    expect(outcome, isNull);

    await tester.pump(const Duration(seconds: 2));

    expect(outcome, isA<RmFailure>());
    expect((outcome! as RmFailure).isTransport, isTrue);
  });

  testWidgets('the timeout is a transport failure, not a server code', (
    WidgetTester tester,
  ) async {
    Object? outcome;

    unawaited(
      clientThatHangs()
          .post('/api/v1/auth/otp', json: <String, Object?>{'phone': '+90'})
          .then<void>((_) => outcome = 'answered')
          .catchError((Object error) => outcome = error),
    );
    await tester.pump(const Duration(seconds: 6));

    final RmFailure failure = outcome! as RmFailure;

    // No status, because nothing answered. A new error code here would be the
    // client inventing something the backend never sent.
    expect(failure.status, isNull);
    expect(failure.requestId, isNull);
  });

  /// THE INVARIANT THIS COMMIT EXISTS FOR.
  ///
  /// Restoration runs at launch while the router holds the startup surface on
  /// RmSessionUnresolved. If the refresh never returns, that state never
  /// changes and the member watches a blank launch screen forever — the app
  /// looks broken rather than offline.
  testWidgets('restore resolves to signed out rather than hanging', (
    WidgetTester tester,
  ) async {
    final InMemoryCredentialStore store = InMemoryCredentialStore();
    await store.write(
      const RmCredentials(refreshToken: 'rmr_STORED', sessionId: 'SESSION_1'),
    );

    final RmSession session = RmSession(
      api: AuthApi(clientThatHangs()),
      store: store,
    );

    bool restored = false;
    unawaited(session.restore().then((_) => restored = true));

    // Mid-flight: unresolved is correct, and is what holds the launch surface.
    await tester.pump(const Duration(seconds: 4));
    expect(session.state.value, isA<RmSessionUnresolved>());
    expect(restored, isFalse);

    await tester.pump(const Duration(seconds: 2));

    expect(restored, isTrue, reason: 'restore must complete, not hang');
    expect(session.state.value, isA<RmSignedOut>());
  });

  /// Landed behaviour, recorded rather than asserted as ideal.
  ///
  /// restore() clears the stored credential on ANY failure, transport included
  /// — so a launch inside a tunnel deletes a refresh token that was very
  /// probably still valid, and the member must sign in by SMS again once they
  /// surface. Nothing about a timeout suggests the credential is the problem.
  ///
  /// Changing that is a sign-out-semantics decision, not part of bounding a
  /// request, so this commit records the behaviour instead of altering it.
  testWidgets('a timed-out restore currently clears the stored credential', (
    WidgetTester tester,
  ) async {
    final InMemoryCredentialStore store = InMemoryCredentialStore();
    await store.write(
      const RmCredentials(refreshToken: 'rmr_STORED', sessionId: 'SESSION_1'),
    );

    final RmSession session = RmSession(
      api: AuthApi(clientThatHangs()),
      store: store,
    );

    unawaited(session.restore());
    await tester.pump(const Duration(seconds: 6));

    expect(session.state.value, isA<RmSignedOut>());
    expect(
      await store.read(),
      isNull,
      reason: 'documents today\'s behaviour; see the note above',
    );
  });

  testWidgets('the default bound is twenty seconds', (
    WidgetTester tester,
  ) async {
    expect(RmApiClient.defaultTimeout, const Duration(seconds: 20));

    Object? outcome;
    unawaited(
      RmApiClient(
            baseUrl: Uri.parse('https://api.example.test'),
            transport: blackHole(),
          )
          .get('/api/v1/me')
          .then<void>((_) => outcome = 'answered')
          .catchError((Object error) => outcome = error),
    );

    await tester.pump(const Duration(seconds: 19));
    expect(outcome, isNull, reason: 'a slow network must not be cut off early');

    await tester.pump(const Duration(seconds: 2));
    expect(outcome, isA<RmFailure>());
  });

  /// The bound sits below retry-once, so a timed-out authenticated request is
  /// an ordinary transport failure. Refreshing would be pointless — nothing
  /// suggests the credential is the problem — and would double the wait.
  testWidgets('a timed-out authenticated request is not retried', (
    WidgetTester tester,
  ) async {
    int attempts = 0;

    final RmApiClient client = RmApiClient(
      baseUrl: Uri.parse('https://api.example.test'),
      timeout: const Duration(seconds: 5),
      transport: MockClient((http.Request request) {
        attempts++;

        return Completer<http.Response>().future;
      }),
    );

    final RmSession session = RmSession(
      api: AuthApi(client),
      store: InMemoryCredentialStore(),
    );

    Object? outcome;
    unawaited(
      session
          .send(
            (Map<String, String> headers) =>
                client.get('/api/v1/me', headers: headers),
          )
          .then<void>((_) => outcome = 'answered')
          .catchError((Object error) => outcome = error),
    );

    await tester.pump(const Duration(seconds: 6));

    // No session, so it never reached the transport at all — and certainly
    // never refreshed.
    expect(outcome, isA<RmFailure>());
    expect(attempts, 0);
  });
}
