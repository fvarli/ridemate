import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ridemate/core/api/rm_api_client.dart';
import 'package:ridemate/core/api/rm_error_code.dart';
import 'package:ridemate/core/api/rm_failure.dart';
import 'package:ridemate/core/session/auth_api.dart';
import 'package:ridemate/core/session/credential_store.dart';
import 'package:ridemate/core/session/rm_credentials.dart';
import 'package:ridemate/core/session/rm_session.dart';
import 'package:ridemate/core/session/rm_token_pair.dart';

/// The session: sign-in, cold start, rotation, single-flight refresh, sign-out.
///
/// Everything runs over an injected fake transport, so no test reaches a
/// network. The session drives the real RmApiClient and the real AuthApi —
/// only the socket is replaced.
void main() {
  late List<http.Request> sent;

  http.Response json(Object? body, {int status = 200}) => http.Response(
    jsonEncode(body),
    status,
    headers: <String, String>{'content-type': 'application/json'},
  );

  http.Response pair({
    String access = 'rma_ACCESS_1',
    String refresh = 'rmr_REFRESH_1',
    String session = 'SESSION_1',
  }) => json(<String, Object?>{
    'access_token': access,
    'refresh_token': refresh,
    'token_type': 'Bearer',
    'expires_in': 900,
    'session_id': session,
  });

  http.Response envelope(String code, {int status = 400}) =>
      json(<String, Object?>{
        'error': <String, Object?>{
          'code': code,
          'message': 'Developer-facing English the member must never see.',
          'request_id': '00000000-0000-7000-8000-0000000000ff',
        },
      }, status: status);

  late RmApiClient client;

  RmSession sessionWith(
    FutureOr<http.Response> Function(http.Request request) respond, {
    CredentialStore? store,
  }) {
    sent = <http.Request>[];

    // One client for both the session's own calls and whatever a caller sends
    // through send(), so every request in a test lands on the same transport
    // and the ordering between them is real.
    client = RmApiClient(
      baseUrl: Uri.parse('https://api.example.test'),
      transport: MockClient((http.Request request) async {
        sent.add(request);

        return await respond(request);
      }),
    );

    return RmSession(
      api: AuthApi(client),
      store: store ?? InMemoryCredentialStore(),
    );
  }

  List<String> pathsCalled() =>
      sent.map((http.Request r) => r.url.path).toList();

  // ------------------------------------------------------------- passcode

  group('Requesting a passcode', () {
    test('a successful request reaches the documented endpoint', () async {
      await sessionWith(
        (_) => json(<String, Object?>{'status': 'accepted'}, status: 202),
      ).requestPasscode('0532 123 45 67');

      expect(pathsCalled(), <String>['/api/v1/auth/otp']);
      expect(jsonDecode(sent.single.body), <String, Object?>{
        'phone': '0532 123 45 67',
      });
    });

    test('a rate limit surfaces as a typed failure', () async {
      await expectLater(
        sessionWith(
          (_) => envelope('rate_limited', status: 429),
        ).requestPasscode('0532 123 45 67'),
        throwsA(
          isA<RmFailure>().having(
            (RmFailure f) => f.code,
            'code',
            RmErrorCode.rateLimited,
          ),
        ),
      );
    });

    test('an unusable number surfaces as a validation failure', () async {
      await expectLater(
        sessionWith(
          (_) => envelope('validation_failed', status: 422),
        ).requestPasscode('nope'),
        throwsA(
          isA<RmFailure>().having(
            (RmFailure f) => f.code,
            'code',
            RmErrorCode.validationFailed,
          ),
        ),
      );
    });
  });

  // --------------------------------------------------------------- verify

  group('Verifying a passcode', () {
    test(
      'it persists the refresh half and keeps the access token in memory',
      () async {
        final InMemoryCredentialStore store = InMemoryCredentialStore();
        final RmSession session = sessionWith((_) => pair(), store: store);

        await session.verifyPasscode(phone: '+905321234567', code: '123456');

        expect(session.state.value, isA<RmSignedIn>());
        expect(
          await store.read(),
          const RmCredentials(
            refreshToken: 'rmr_REFRESH_1',
            sessionId: 'SESSION_1',
          ),
        );
        expect(session.accessTokenForTest, 'rma_ACCESS_1');
      },
    );

    /// CARRIES WEIGHT. Registration and sign-in are one call by contract, and
    /// the client must not be able to tell them apart — if it could, so could
    /// anyone watching it.
    test(
      'a first account and a returning member are indistinguishable',
      () async {
        final RmSession first = sessionWith((_) => pair());
        await first.verifyPasscode(phone: '+905321234567', code: '123456');
        final List<String> firstCalls = pathsCalled();
        final String firstBody = sent.single.body;

        final RmSession returning = sessionWith((_) => pair());
        await returning.verifyPasscode(phone: '+905321234567', code: '123456');

        expect(pathsCalled(), firstCalls);
        expect(sent.single.body, firstBody);
        expect(first.state.value, isA<RmSignedIn>());
        expect(returning.state.value, isA<RmSignedIn>());
      },
    );

    test('a suspended account is forbidden, and distinctly so', () async {
      final RmSession session = sessionWith(
        (_) => envelope('forbidden', status: 403),
      );

      await expectLater(
        session.verifyPasscode(phone: '+905321234567', code: '123456'),
        throwsA(
          isA<RmFailure>().having(
            (RmFailure f) => f.code,
            'code',
            RmErrorCode.forbidden,
          ),
        ),
      );
      // Not signed in, which is the property that matters. The exact
      // non-signed-in state depends on whether restore() ran first, and a
      // refusal from the server does not change it either way.
      expect(session.state.value, isNot(isA<RmSignedIn>()));
    });

    test('a wrong passcode leaves nothing behind', () async {
      final InMemoryCredentialStore store = InMemoryCredentialStore();
      final RmSession session = sessionWith(
        (_) => envelope('unauthenticated', status: 401),
        store: store,
      );

      await expectLater(
        session.verifyPasscode(phone: '+905321234567', code: '000000'),
        throwsA(isA<RmFailure>()),
      );
      expect(await store.read(), isNull);
      expect(session.accessTokenForTest, isNull);
    });

    test('an unrecognised server code degrades to unexpected', () async {
      await expectLater(
        sessionWith(
          (_) => envelope('teapot_overflow', status: 418),
        ).verifyPasscode(phone: '+905321234567', code: '123456'),
        throwsA(
          isA<RmFailure>().having(
            (RmFailure f) => f.code,
            'code',
            RmErrorCode.unexpected,
          ),
        ),
      );
    });

    /// FAIL CLOSED. Rotation has already spent the previous generation
    /// server-side, so a session that cannot be written is unrecoverable after
    /// a restart. Signing out now costs one passcode; continuing costs the
    /// member a silent sign-out later.
    test('a credential that cannot be persisted signs out instead', () async {
      final RmSession session = sessionWith(
        (_) => pair(),
        store: _UnwritableStore(),
      );

      await expectLater(
        session.verifyPasscode(phone: '+905321234567', code: '123456'),
        throwsA(isA<RmFailure>()),
      );
      expect(session.state.value, isA<RmSignedOut>());
      expect(session.accessTokenForTest, isNull);
    });
  });

  // ------------------------------------------------------------ cold start

  group('Cold start', () {
    test('no stored credential means signed out', () async {
      final RmSession session = sessionWith((_) => pair());

      await session.restore();

      expect(session.state.value, isA<RmSignedOut>());
      expect(sent, isEmpty, reason: 'nothing to exchange, so nothing is sent');
    });

    test('a stored credential is exchanged for a live session', () async {
      final InMemoryCredentialStore store = InMemoryCredentialStore();
      await store.write(
        const RmCredentials(refreshToken: 'rmr_OLD', sessionId: 'SESSION_1'),
      );

      final RmSession session = sessionWith(
        (_) => pair(access: 'rma_NEW', refresh: 'rmr_NEW'),
        store: store,
      );
      await session.restore();

      expect(session.state.value, isA<RmSignedIn>());
      expect(pathsCalled(), <String>['/api/v1/auth/refresh']);
      // Rotation replaced what is stored; the spent token is gone.
      expect((await store.read())?.refreshToken, 'rmr_NEW');
    });

    test('a refused credential is cleared, not kept hopefully', () async {
      final InMemoryCredentialStore store = InMemoryCredentialStore();
      await store.write(
        const RmCredentials(refreshToken: 'rmr_DEAD', sessionId: 'SESSION_1'),
      );

      final RmSession session = sessionWith(
        (_) => envelope('unauthenticated', status: 401),
        store: store,
      );
      await session.restore();

      expect(session.state.value, isA<RmSignedOut>());
      expect(await store.read(), isNull);
    });

    test('restoring never throws, even when the network is gone', () async {
      final InMemoryCredentialStore store = InMemoryCredentialStore();
      await store.write(
        const RmCredentials(refreshToken: 'rmr_OLD', sessionId: 'SESSION_1'),
      );

      final RmSession session = sessionWith(
        (_) => throw http.ClientException('offline'),
        store: store,
      );

      await session.restore();

      expect(session.state.value, isA<RmSignedOut>());
    });
  });

  // ------------------------------------------------------ refresh and retry

  group('Refreshing on a 401', () {
    /// Signs a session in, then clears the request log so each test starts
    /// from a known point.
    Future<RmSession> signedIn(
      http.Response Function(http.Request request) respond, {
      CredentialStore? store,
    }) async {
      final RmSession session = sessionWith((http.Request request) {
        if (request.url.path == '/api/v1/auth/otp/verify') {
          return pair();
        }

        return respond(request);
      }, store: store);

      await session.verifyPasscode(phone: '+905321234567', code: '123456');
      sent.clear();

      return session;
    }

    /// The request a caller makes through the session.
    Future<void> callMe(RmSession session) => session.send(
      (Map<String, String> headers) =>
          client.get('/api/v1/me', headers: headers),
    );

    /// CARRIES WEIGHT. Exactly one refresh, exactly one retry.
    test('a 401 refreshes once and retries once with the new token', () async {
      final List<String?> tokens = <String?>[];
      int meCalls = 0;

      final RmSession session = await signedIn((http.Request request) {
        if (request.url.path == '/api/v1/auth/refresh') {
          return pair(access: 'rma_ACCESS_2', refresh: 'rmr_REFRESH_2');
        }

        tokens.add(request.headers['authorization']);

        return ++meCalls == 1
            ? envelope('unauthenticated', status: 401)
            : json(<String, Object?>{
                'account': <String, Object?>{'id': 'x'},
              });
      });

      await callMe(session);

      expect(pathsCalled(), <String>[
        '/api/v1/me',
        '/api/v1/auth/refresh',
        '/api/v1/me',
      ]);
      expect(tokens, <String>[
        'Bearer rma_ACCESS_1',
        'Bearer rma_ACCESS_2',
      ], reason: 'the retry must carry the NEW token');
    });

    /// No loop. A credential the backend has already refused twice is not
    /// going to work on a third attempt, and retrying would turn one bad
    /// session into sustained traffic.
    test('a retry that also fails stops there', () async {
      int meCalls = 0;

      final RmSession session = await signedIn((http.Request request) {
        if (request.url.path == '/api/v1/auth/refresh') {
          return pair(access: 'rma_ACCESS_2', refresh: 'rmr_REFRESH_2');
        }
        meCalls++;

        return envelope('unauthenticated', status: 401);
      });

      await expectLater(callMe(session), throwsA(isA<RmFailure>()));

      expect(meCalls, 2, reason: 'the original and exactly one retry');
      expect(
        pathsCalled().where((String p) => p.endsWith('refresh')).length,
        1,
      );
    });

    /// CARRIES WEIGHT, AND IT IS THE REASON SINGLE-FLIGHT EXISTS.
    ///
    /// Without it each concurrent 401 would call /auth/refresh with the same
    /// token: the first rotates it, and the rest present a generation that was
    /// just spent — which the backend treats as theft and answers by revoking
    /// the whole family. Client concurrency would look exactly like a stolen
    /// credential.
    test('concurrent 401s share exactly one refresh', () async {
      int refreshes = 0;
      final Map<String, int> meCallsByToken = <String, int>{};

      final RmSession session = await signedIn((http.Request request) {
        if (request.url.path == '/api/v1/auth/refresh') {
          refreshes++;

          return pair(access: 'rma_ACCESS_2', refresh: 'rmr_REFRESH_2');
        }

        final String token = request.headers['authorization'] ?? '';
        meCallsByToken[token] = (meCallsByToken[token] ?? 0) + 1;

        return token.endsWith('rma_ACCESS_1')
            ? envelope('unauthenticated', status: 401)
            : json(<String, Object?>{
                'account': <String, Object?>{'id': 'x'},
              });
      });

      await Future.wait<void>(<Future<void>>[
        callMe(session),
        callMe(session),
        callMe(session),
        callMe(session),
        callMe(session),
      ]);

      expect(refreshes, 1, reason: 'five waiters, one refresh');
      expect(meCallsByToken['Bearer rma_ACCESS_1'], 5);
      expect(
        meCallsByToken['Bearer rma_ACCESS_2'],
        5,
        reason: 'each caller retries its own request once',
      );
    });

    test(
      'when the shared refresh fails, every waiter fails the same way',
      () async {
        int refreshes = 0;

        final RmSession session = await signedIn((http.Request request) {
          if (request.url.path == '/api/v1/auth/refresh') {
            refreshes++;

            return envelope('unauthenticated', status: 401);
          }

          return envelope('unauthenticated', status: 401);
        });

        final List<Object>
        outcomes = await Future.wait<Object>(<Future<Object>>[
          callMe(session).then<Object>((_) => 'ok').catchError((Object e) => e),
          callMe(session).then<Object>((_) => 'ok').catchError((Object e) => e),
          callMe(session).then<Object>((_) => 'ok').catchError((Object e) => e),
        ]);

        expect(outcomes.every((Object o) => o is RmFailure), isTrue);
        expect(refreshes, 1);
        expect(session.state.value, isA<RmSignedOut>());
      },
    );

    /// A 401 from the refresh endpoint must not trigger a refresh. AuthApi
    /// calls the raw client for exactly this reason.
    test('the refresh endpoint never refreshes recursively', () async {
      int refreshes = 0;

      final RmSession session = await signedIn((http.Request request) {
        if (request.url.path == '/api/v1/auth/refresh') {
          refreshes++;

          return envelope('unauthenticated', status: 401);
        }

        return envelope('unauthenticated', status: 401);
      });

      await expectLater(callMe(session), throwsA(isA<RmFailure>()));

      expect(refreshes, 1, reason: 'recursion would make this climb');
    });

    /// Rotation replaces what is stored before the new pair is used, so a
    /// restart after a refresh finds the generation the server expects.
    test('a successful rotation replaces the persisted credential', () async {
      final InMemoryCredentialStore store = InMemoryCredentialStore();
      int meCalls = 0;

      final RmSession session = await signedIn((http.Request request) {
        if (request.url.path == '/api/v1/auth/refresh') {
          return pair(access: 'rma_ACCESS_2', refresh: 'rmr_REFRESH_2');
        }

        return ++meCalls == 1
            ? envelope('unauthenticated', status: 401)
            : json(<String, Object?>{
                'account': <String, Object?>{'id': 'x'},
              });
      }, store: store);

      await callMe(session);

      expect((await store.read())?.refreshToken, 'rmr_REFRESH_2');
    });

    /// A rotation that cannot be written leaves a session that works until the
    /// process ends and is unrecoverable afterwards — the previous generation
    /// is already spent server-side.
    test('a rotation that cannot be persisted signs out', () async {
      final RmSession session = await signedIn((http.Request request) {
        if (request.url.path == '/api/v1/auth/refresh') {
          return pair(access: 'rma_ACCESS_2', refresh: 'rmr_REFRESH_2');
        }

        return envelope('unauthenticated', status: 401);
      }, store: _WriteOnceStore());

      await expectLater(callMe(session), throwsA(isA<RmFailure>()));

      expect(session.state.value, isA<RmSignedOut>());
      expect(session.accessTokenForTest, isNull);
    });

    test(
      'a request with no session at all does not reach the network',
      () async {
        final RmSession session = sessionWith((_) => pair());

        await expectLater(callMe(session), throwsA(isA<RmFailure>()));
        expect(sent, isEmpty);
      },
    );

    /// A 403 is a decision about the account, not an expired credential.
    /// Refreshing would produce the same answer and waste a generation.
    test('a forbidden response is not retried', () async {
      int refreshes = 0;

      final RmSession session = await signedIn((http.Request request) {
        if (request.url.path == '/api/v1/auth/refresh') {
          refreshes++;

          return pair();
        }

        return envelope('forbidden', status: 403);
      });

      await expectLater(
        callMe(session),
        throwsA(
          isA<RmFailure>().having(
            (RmFailure f) => f.code,
            'code',
            RmErrorCode.forbidden,
          ),
        ),
      );
      expect(refreshes, 0);
    });
  });

  group('Sign-out', () {
    test('it revokes the server session and clears locally', () async {
      final InMemoryCredentialStore store = InMemoryCredentialStore();
      final RmSession session = sessionWith((_) => pair(), store: store);
      await session.verifyPasscode(phone: '+905321234567', code: '123456');
      sent.clear();

      await session.signOut();

      expect(pathsCalled(), <String>['/api/v1/auth/logout']);
      expect(await store.read(), isNull);
      expect(session.state.value, isA<RmSignedOut>());
      expect(session.accessTokenForTest, isNull);
    });

    /// A member who taps sign out on a train with no signal must not still be
    /// signed in on the device in front of them. The server session outlives
    /// it until its own expiry, which is the smaller problem.
    test('a failed revocation still clears the device', () async {
      final List<String> reported = <String>[];
      final DebugPrintCallback original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) =>
          reported.add(message ?? '');

      final InMemoryCredentialStore store = InMemoryCredentialStore();
      final RmSession session = sessionWith((http.Request request) {
        if (request.url.path == '/api/v1/auth/logout') {
          throw http.ClientException('offline');
        }

        return pair();
      }, store: store);
      await session.verifyPasscode(phone: '+905321234567', code: '123456');

      await session.signOut();

      debugPrint = original;

      expect(await store.read(), isNull);
      expect(session.state.value, isA<RmSignedOut>());
      expect(
        reported.join('\n'),
        contains('revoking the session'),
        reason: 'the failure must be reported, not swallowed',
      );
    });
  });

  /// Sign-out is local first, then a best-effort revocation of THIS session.
  ///
  /// The revocation uses what the device held when the member asked — and a
  /// refresh that was already out when they did can neither sign them back in
  /// nor leave a credential behind.
  group('Sign-out, revoking the current session', () {
    http.Response noContent() => http.Response('', 204);

    String? bearerOf(http.Request request) => request.headers['authorization'];

    Future<RmSession> signedIn(
      FutureOr<http.Response> Function(http.Request request) respond, {
      CredentialStore? store,
    }) async {
      final RmSession session = sessionWith((http.Request request) {
        if (request.url.path == '/api/v1/auth/otp/verify') return pair();

        return respond(request);
      }, store: store);

      await session.verifyPasscode(phone: '+905321234567', code: '123456');
      sent.clear();

      return session;
    }

    test('the current access token revokes the current session', () async {
      final _RecordingStore store = _RecordingStore();
      final RmSession session = await signedIn(
        (_) => noContent(),
        store: store,
      );

      await session.signOut();

      expect(pathsCalled(), <String>['/api/v1/auth/logout']);
      expect(bearerOf(sent.single), 'Bearer rma_ACCESS_1');
      expect(await store.read(), isNull);
      expect(session.state.value, isA<RmSignedOut>());
      expect(session.consumeSignedOutReason(), isNull);
    });

    /// CARRIES WEIGHT. Access tokens live fifteen minutes and nothing renews
    /// one proactively, so a member who has sat on Profile for a while signs
    /// out holding an expired one. Stopping at its 401 would leave the session
    /// refreshable on the server for up to thirty days.
    test('an expired access token is exchanged once, only to revoke', () async {
      final _RecordingStore store = _RecordingStore();
      final List<http.Request> logouts = <http.Request>[];

      final RmSession session = await signedIn((http.Request request) {
        switch (request.url.path) {
          case '/api/v1/auth/refresh':
            return pair(access: 'rma_ACCESS_2', refresh: 'rmr_REFRESH_2');
          case '/api/v1/auth/logout':
            logouts.add(request);

            return logouts.length == 1
                ? envelope('unauthenticated', status: 401)
                : noContent();
        }

        return envelope('internal_error', status: 500);
      }, store: store);
      store.writes.clear();

      await session.signOut();

      // This session's refresh token, and nothing broader: there is no call
      // here that could speak for another device.
      expect(pathsCalled(), <String>[
        '/api/v1/auth/logout',
        '/api/v1/auth/refresh',
        '/api/v1/auth/logout',
      ]);
      expect(jsonDecode(sent[1].body), <String, Object?>{
        'refresh_token': 'rmr_REFRESH_1',
      });
      expect(bearerOf(logouts.last), 'Bearer rma_ACCESS_2');

      // Used for the revocation and nothing else: never stored, never adopted.
      expect(store.writes, isEmpty);
      expect(await store.read(), isNull);
      expect(session.state.value, isA<RmSignedOut>());
      expect(session.accessTokenForTest, isNull);
      expect(session.consumeSignedOutReason(), isNull);
    });

    /// A refresh the server refuses proves there is nothing left to revoke.
    /// That is the outcome asked for, so it is neither retried nor reported.
    test('a session that is already dead is left at that', () async {
      final List<String> reported = <String>[];
      final DebugPrintCallback original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) =>
          reported.add(message ?? '');
      addTearDown(() => debugPrint = original);

      final RmSession session = await signedIn(
        (_) => envelope('unauthenticated', status: 401),
      );

      await session.signOut();

      expect(pathsCalled(), <String>[
        '/api/v1/auth/logout',
        '/api/v1/auth/refresh',
      ]);
      expect(session.state.value, isA<RmSignedOut>());
      expect(session.consumeSignedOutReason(), isNull);
      expect(reported.join('\n'), isNot(contains('revoking the session')));
    });

    /// The device is signed out before anything is sent, so a request that
    /// never answers keeps nobody signed in while it waits.
    test('the device is signed out before the revocation answers', () async {
      final Completer<http.Response> logout = Completer<http.Response>();
      final InMemoryCredentialStore store = InMemoryCredentialStore();
      final RmSession session = await signedIn(
        (_) => logout.future,
        store: store,
      );

      final Future<void> signingOut = session.signOut();
      await pumpEventQueue();

      expect(pathsCalled(), <String>['/api/v1/auth/logout']);
      expect(session.state.value, isA<RmSignedOut>());
      expect(await store.read(), isNull);

      logout.complete(noContent());
      await signingOut;
    });

    /// CARRIES WEIGHT. A refresh already out when the member signs out must
    /// not land afterwards: no access token, no stored credential, and no
    /// return to RmSignedIn — which is what would take them back into the app.
    test('a refresh in flight cannot sign the member back in', () async {
      final Completer<http.Response> refresh = Completer<http.Response>();
      final _RecordingStore store = _RecordingStore();
      int meCalls = 0;

      final RmSession session = await signedIn((http.Request request) {
        switch (request.url.path) {
          case '/api/v1/auth/refresh':
            return refresh.future;
          case '/api/v1/auth/logout':
            return noContent();
        }
        meCalls++;

        return envelope('unauthenticated', status: 401);
      }, store: store);
      store.writes.clear();

      // A request whose token has expired, so it is waiting on a refresh.
      final Future<Object?> call = _outcomeOf(
        session.send(
          (Map<String, String> headers) =>
              client.get('/api/v1/me', headers: headers),
        ),
      );
      await pumpEventQueue();
      expect(pathsCalled(), <String>['/api/v1/me', '/api/v1/auth/refresh']);

      final List<RmSessionState> seen = <RmSessionState>[];
      session.state.addListener(() => seen.add(session.state.value));

      final Future<void> signingOut = session.signOut();
      await pumpEventQueue();
      expect(session.state.value, isA<RmSignedOut>());

      refresh.complete(pair(access: 'rma_ACCESS_2', refresh: 'rmr_REFRESH_2'));
      await signingOut;

      // The caller is refused rather than retried for somebody who has left.
      expect(
        await call,
        isA<RmFailure>().having(
          (RmFailure f) => f.code,
          'code',
          RmErrorCode.unauthenticated,
        ),
      );
      expect(meCalls, 1);

      expect(seen.whereType<RmSignedIn>(), isEmpty);
      expect(session.state.value, isA<RmSignedOut>());
      expect(session.accessTokenForTest, isNull);
      expect(store.writes, isEmpty);
      expect(await store.read(), isNull);
      expect(session.consumeSignedOutReason(), isNull);

      // The pair that refresh produced is the live credential — the one it
      // was handed spent the old refresh token — so it is what revokes.
      final http.Request revocation = sent.last;
      expect(revocation.url.path, '/api/v1/auth/logout');
      expect(bearerOf(revocation), 'Bearer rma_ACCESS_2');
    });

    /// The same race, refused by the server instead: it must not attach a
    /// "your session ended" notice to a sign-out the member chose.
    test('a refresh refused after sign-out adds no notice', () async {
      final Completer<http.Response> refresh = Completer<http.Response>();

      final RmSession session = await signedIn((http.Request request) {
        switch (request.url.path) {
          case '/api/v1/auth/refresh':
            return refresh.future;
          case '/api/v1/auth/logout':
            return noContent();
        }

        return envelope('unauthenticated', status: 401);
      });

      final Future<Object?> call = _outcomeOf(
        session.send(
          (Map<String, String> headers) =>
              client.get('/api/v1/me', headers: headers),
        ),
      );
      await pumpEventQueue();

      final Future<void> signingOut = session.signOut();
      await pumpEventQueue();

      refresh.complete(envelope('unauthenticated', status: 401));
      await signingOut;
      expect(await call, isA<RmFailure>());

      expect(session.state.value, isA<RmSignedOut>());
      expect(session.consumeSignedOutReason(), isNull);
      expect(
        pathsCalled().where((String p) => p.endsWith('logout')),
        isEmpty,
        reason: 'the server has already said the session is gone',
      );
    });

    /// CARRIES WEIGHT. A request member A made that is still out when A
    /// leaves and B signs in must not be refreshed and retried with B's
    /// credential — that would send A's request as B.
    test(
      'a request made before sign-out is never retried as somebody else',
      () async {
        final Completer<http.Response> aRequest = Completer<http.Response>();
        final List<String?> meTokens = <String?>[];
        int signIns = 0;

        final RmSession session = sessionWith((http.Request request) {
          switch (request.url.path) {
            case '/api/v1/auth/otp/verify':
              return ++signIns == 1
                  ? pair()
                  : pair(access: 'rma_B', refresh: 'rmr_B', session: 'S_B');
            case '/api/v1/auth/logout':
              return noContent();
            case '/api/v1/auth/refresh':
              return pair(access: 'rma_B_2', refresh: 'rmr_B_2');
          }
          meTokens.add(bearerOf(request));

          return aRequest.future;
        });
        await session.verifyPasscode(phone: '+905321234567', code: '123456');

        final Future<Object?> call = _outcomeOf(
          session.send(
            (Map<String, String> headers) =>
                client.get('/api/v1/me', headers: headers),
          ),
        );
        await pumpEventQueue();

        await session.signOut();
        await session.verifyPasscode(phone: '+905329876543', code: '654321');
        sent.clear();

        aRequest.complete(envelope('unauthenticated', status: 401));

        expect(await call, isA<RmFailure>());
        expect(pathsCalled(), isEmpty, reason: 'no refresh, and no retry');
        expect(meTokens, <String>['Bearer rma_ACCESS_1']);
        expect(session.state.value, isA<RmSignedIn>());
        expect(session.accessTokenForTest, 'rma_B');
      },
    );

    /// The narrowest version of the race: the refresh answered, and its
    /// credential was being written when the member signed out. The write
    /// cannot be recalled, so it is undone.
    test('a credential being written when sign-out begins is undone', () async {
      final _HeldStore store = _HeldStore();

      final RmSession session = await signedIn((http.Request request) {
        switch (request.url.path) {
          case '/api/v1/auth/refresh':
            return pair(access: 'rma_ACCESS_2', refresh: 'rmr_REFRESH_2');
          case '/api/v1/auth/logout':
            return noContent();
        }

        return envelope('unauthenticated', status: 401);
      }, store: store);

      store.hold();
      final Future<Object?> call = _outcomeOf(
        session.send(
          (Map<String, String> headers) =>
              client.get('/api/v1/me', headers: headers),
        ),
      );
      await pumpEventQueue();
      expect(store.writing, isTrue);

      final Future<void> signingOut = session.signOut();
      await pumpEventQueue();
      store.release();
      await signingOut;
      expect(await call, isA<RmFailure>());

      expect(await store.read(), isNull);
      expect(session.state.value, isA<RmSignedOut>());
      expect(session.accessTokenForTest, isNull);
      expect(bearerOf(sent.last), 'Bearer rma_ACCESS_2');
    });
  });

  group('Nothing secret is logged', () {
    /// The reporter writes to the developer log. A full sign-in, rotation and
    /// sign-out is driven with failures at every step — which is when things
    /// get reported — and the output is then searched for every secret that
    /// passed through.
    test('no token, passcode or number reaches the log', () async {
      final List<String> reported = <String>[];
      final DebugPrintCallback original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) =>
          reported.add(message ?? '');

      const String phone = '+905321234567';
      const String passcode = '481523';

      final RmSession session = sessionWith((http.Request request) {
        if (request.url.path == '/api/v1/auth/otp/verify') {
          return pair(
            access: 'rma_SECRET_ACCESS',
            refresh: 'rmr_SECRET_REFRESH',
          );
        }
        if (request.url.path == '/api/v1/auth/logout') {
          throw http.ClientException('offline');
        }

        return envelope('internal_error', status: 500);
      });

      await session.requestPasscode(phone).catchError((Object _) {});
      await session.verifyPasscode(phone: phone, code: passcode);
      await session.signOut();

      debugPrint = original;

      final String log = reported.join('\n');

      expect(log, isNotEmpty, reason: 'something should have been reported');
      for (final String secret in <String>[
        'rma_SECRET_ACCESS',
        'rmr_SECRET_REFRESH',
        passcode,
        phone,
        '905321234567',
      ]) {
        expect(log, isNot(contains(secret)), reason: secret);
      }
    });

    /// The pair redacts itself, so an interpolated object cannot leak one.
    test('the token pair prints without its tokens', () {
      const RmTokenPair pair = RmTokenPair(
        accessToken: 'rma_SECRET',
        refreshToken: 'rmr_SECRET',
        sessionId: 'SESSION_1',
        expiresIn: 900,
      );

      expect(pair.toString(), isNot(contains('SECRET')));
      expect(pair.toString(), contains('SESSION_1'));
    });
  });

  group('A store that cannot persist can never sign anyone in', () {
    /// REGRESSION. InMemoryCredentialStore used to be the fallback when the
    /// platform keystore could not be opened, and its write returned true — so
    /// the session believed the credential was durable, signed in, and lost it
    /// at the next launch. Signing in has already spent a refresh generation
    /// server-side by then, so the member could not recover either.
    ///
    /// The degraded store is now the real production class, not a double.
    test('verifying a passcode cannot reach signed in', () async {
      final RmSession session = sessionWith(
        (_) => pair(),
        store: const UnavailableCredentialStore(),
      );

      await expectLater(
        session.verifyPasscode(phone: '+905321234567', code: '123456'),
        throwsA(isA<RmFailure>()),
      );

      expect(session.state.value, isA<RmSignedOut>());
      expect(session.accessTokenForTest, isNull);
    });

    test('a refresh cannot reach signed in either', () async {
      final RmSession session = sessionWith(
        (_) => pair(),
        store: const UnavailableCredentialStore(),
      );

      // Nothing to restore from, because nothing could ever have been stored.
      await session.restore();

      expect(session.state.value, isA<RmSignedOut>());
      expect(sent, isEmpty);
    });

    test('the degraded store reports its writes as not durable', () async {
      const UnavailableCredentialStore store = UnavailableCredentialStore();

      expect(
        await store.write(
          const RmCredentials(refreshToken: 'rmr_X', sessionId: 'S'),
        ),
        isFalse,
      );
      expect(await store.read(), isNull);
    });

    /// The in-memory store keeps its `true`, because for its actual users —
    /// tests and the provider default — the value really is retrievable.
    test('the in-memory store is still honest about being durable', () async {
      final InMemoryCredentialStore store = InMemoryCredentialStore();

      expect(
        await store.write(
          const RmCredentials(refreshToken: 'rmr_X', sessionId: 'S'),
        ),
        isTrue,
      );
      expect((await store.read())?.refreshToken, 'rmr_X');
    });
  });

  group('The initial state', () {
    /// REGRESSION. The session used to start signed-out, which is a claim
    /// nothing had checked yet. The router reads this state to choose between
    /// holding the startup surface and showing a sign-in form, so a session
    /// that began signed-out made the form appear and vanish on every cold
    /// start for anyone who was already signed in — the exact flicker the
    /// unresolved state exists to prevent.
    test('a fresh session has not looked yet', () {
      expect(
        sessionWith((_) => pair()).state.value,
        isA<RmSessionUnresolved>(),
      );
    });

    test('restoring with nothing stored resolves it to signed out', () async {
      final RmSession session = sessionWith((_) => pair());

      await session.restore();

      expect(session.state.value, isA<RmSignedOut>());
    });

    test('restoring a valid credential resolves it to signed in', () async {
      final InMemoryCredentialStore store = InMemoryCredentialStore();
      await store.write(
        const RmCredentials(refreshToken: 'rmr_OLD', sessionId: 'SESSION_1'),
      );

      final RmSession session = sessionWith((_) => pair(), store: store);
      expect(session.state.value, isA<RmSessionUnresolved>());

      await session.restore();

      expect(session.state.value, isA<RmSignedIn>());
    });
  });

  group('When a credential may be deleted, and when it may not', () {
    /// The invariant, stated as a matrix. A refresh credential is deleted only
    /// when the server proves it unusable, the member explicitly signs out, or
    /// durable storage fails. Everything else preserves it, because nothing
    /// else is evidence.
    Future<InMemoryCredentialStore> stored() async {
      final InMemoryCredentialStore store = InMemoryCredentialStore();
      await store.write(
        const RmCredentials(refreshToken: 'rmr_STORED', sessionId: 'SESSION_1'),
      );

      return store;
    }

    /// Server said no: the credential is spent, expired or revoked. Keeping it
    /// would mean retrying something that can only fail.
    test('401 deletes it and says the session ended', () async {
      final InMemoryCredentialStore store = await stored();
      final RmSession session = sessionWith(
        (_) => envelope('unauthenticated', status: 401),
        store: store,
      );

      await session.restore();

      expect(await store.read(), isNull);
      expect(session.consumeSignedOutReason(), RmSignedOutReason.sessionEnded);
    });

    /// Also proven unusable, and distinctly so — signing in again is exactly
    /// what will not help a suspended account.
    test('403 deletes it and says the account is suspended', () async {
      final InMemoryCredentialStore store = await stored();
      final RmSession session = sessionWith(
        (_) => envelope('forbidden', status: 403),
        store: store,
      );

      await session.restore();

      expect(await store.read(), isNull);
      expect(
        session.consumeSignedOutReason(),
        RmSignedOutReason.accountSuspended,
      );
    });

    /// Everything below learned NOTHING about the credential.
    for (final (String label, http.Response Function() respond)
        in <(String, http.Response Function())>[
          ('a server error', () => envelope('internal_error', status: 500)),
          ('a rate limit', () => envelope('rate_limited', status: 429)),
          ('a malformed response', () => http.Response('{oh no', 502)),
        ]) {
      test('$label preserves it', () async {
        final InMemoryCredentialStore store = await stored();
        final RmSession session = sessionWith((_) => respond(), store: store);

        await session.restore();

        expect(session.state.value, isA<RmSignedOut>());
        expect(
          (await store.read())?.refreshToken,
          'rmr_STORED',
          reason: '$label is not evidence the credential is bad',
        );
        expect(
          session.consumeSignedOutReason(),
          isNull,
          reason: 'nothing ended; the app just could not find out',
        );
      });
    }

    test('a dropped connection preserves it', () async {
      final InMemoryCredentialStore store = await stored();
      final RmSession session = sessionWith(
        (_) => throw http.ClientException('connection reset'),
        store: store,
      );

      await session.restore();

      expect(session.state.value, isA<RmSignedOut>());
      expect((await store.read())?.refreshToken, 'rmr_STORED');
      expect(session.consumeSignedOutReason(), isNull);
    });

    /// The member asked. No evidence is required, and no notice is shown.
    test('an explicit sign-out deletes it', () async {
      final InMemoryCredentialStore store = InMemoryCredentialStore();
      final RmSession session = sessionWith((_) => pair(), store: store);
      await session.verifyPasscode(phone: '+905321234567', code: '123456');

      await session.signOut();

      expect(await store.read(), isNull);
      expect(session.consumeSignedOutReason(), isNull);
    });

    /// Fail closed: a session that cannot outlive the process must not be
    /// reported as established.
    test('a credential that cannot be written leaves nothing stored', () async {
      final RmSession session = sessionWith(
        (_) => pair(),
        store: const UnavailableCredentialStore(),
      );

      await expectLater(
        session.verifyPasscode(phone: '+905321234567', code: '123456'),
        throwsA(isA<RmFailure>()),
      );

      expect(session.state.value, isA<RmSignedOut>());
    });

    /// restore() must never leave the router holding the launch surface.
    test('every outcome resolves out of unresolved', () async {
      for (final http.Response Function() respond in <http.Response Function()>[
        () => pair(),
        () => envelope('unauthenticated', status: 401),
        () => envelope('forbidden', status: 403),
        () => envelope('internal_error', status: 500),
      ]) {
        final InMemoryCredentialStore store = await stored();
        final RmSession session = sessionWith((_) => respond(), store: store);

        await session.restore();

        expect(session.state.value, isNot(isA<RmSessionUnresolved>()));
      }
    });
  });
}

/// Accepts the first write and refuses every later one, so a session can be
/// established and then fail to persist a rotation.
class _WriteOnceStore implements CredentialStore {
  RmCredentials? _held;
  bool _used = false;

  @override
  Future<RmCredentials?> read() async => _held;

  @override
  Future<bool> write(RmCredentials credentials) async {
    if (_used) {
      return false;
    }
    _used = true;
    _held = credentials;

    return true;
  }

  @override
  Future<void> clear() async => _held = null;
}

/// A store whose writes always fail, for the fail-closed path.
class _UnwritableStore implements CredentialStore {
  RmCredentials? _held;

  @override
  Future<RmCredentials?> read() async => _held;

  @override
  Future<bool> write(RmCredentials credentials) async => false;

  @override
  Future<void> clear() async => _held = null;
}

/// Records every credential offered for storage.
class _RecordingStore extends InMemoryCredentialStore {
  final List<RmCredentials> writes = <RmCredentials>[];

  @override
  Future<bool> write(RmCredentials credentials) {
    writes.add(credentials);

    return super.write(credentials);
  }
}

/// A store whose writes can be held open, the way a slow keystore holds them.
class _HeldStore extends InMemoryCredentialStore {
  Completer<void>? _gate;
  bool writing = false;

  void hold() => _gate ??= Completer<void>();

  void release() {
    _gate?.complete();
    _gate = null;
  }

  @override
  Future<bool> write(RmCredentials credentials) async {
    writing = true;
    await _gate?.future;
    writing = false;

    return super.write(credentials);
  }
}

/// Settles [future] into its value or its error, so a failure that arrives
/// while a test is still arranging the race is observed rather than unhandled.
Future<Object?> _outcomeOf(Future<Object?> future) =>
    future.then<Object?>((Object? value) => value, onError: (Object e) => e);
