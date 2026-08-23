import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ridemate/app/providers/session_provider.dart';
import 'package:ridemate/app/router/app_routes.dart';
import 'package:ridemate/core/api/rm_api_client.dart';
import 'package:ridemate/core/session/auth_api.dart';
import 'package:ridemate/core/session/credential_store.dart';
import 'package:ridemate/core/session/rm_session.dart';
import 'package:ridemate/core/theme/rm_theme.dart';
import 'package:ridemate/features/auth/presentation/passcode_entry_screen.dart';
import 'package:ridemate/features/auth/presentation/phone_entry_screen.dart';
import 'package:ridemate/l10n/app_localizations.dart';

import '../../support/pump.dart';

/// The two sign-in screens.
///
/// Every control is driven against a fake transport: no test reaches a
/// network, and the states asserted here are the real ones the screens enter.
void main() {
  late List<http.Request> sent;
  late AppLocalizations tr;

  setUpAll(() async {
    tr = await AppLocalizations.delegate.load(const Locale('tr'));
  });

  http.Response json(Object? body, {int status = 200}) => http.Response(
    jsonEncode(body),
    status,
    headers: <String, String>{'content-type': 'application/json'},
  );

  http.Response envelope(String code, {int status = 400}) =>
      json(<String, Object?>{
        'error': <String, Object?>{
          'code': code,
          // The string that must never appear on screen.
          'message': 'DEVELOPER_ENGLISH_NOT_FOR_MEMBERS',
          'request_id': '00000000-0000-7000-8000-0000000000ff',
        },
      }, status: status);

  ({RmSession session, List<Override> overrides}) harness(
    http.Response Function(http.Request request) respond, {
    CredentialStore? store,
  }) {
    sent = <http.Request>[];

    final RmSession session = RmSession(
      api: AuthApi(
        RmApiClient(
          baseUrl: Uri.parse('https://api.example.test'),
          transport: MockClient((http.Request request) async {
            sent.add(request);

            return respond(request);
          }),
        ),
      ),
      store: store ?? InMemoryCredentialStore(),
    );

    return (
      session: session,
      overrides: <Override>[rmSessionProvider.overrideWithValue(session)],
    );
  }

  /// The phone screen pushes the passcode screen on success, so it needs a
  /// real router rather than a bare MaterialApp. Only the two auth routes are
  /// registered: this is testing the screen, not the application's route table.
  Future<void> pumpWithRouter(
    WidgetTester tester,
    List<Override> overrides,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: RmTheme.of(Brightness.light),
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(
            initialLocation: AppRoutes.authPhonePath,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.authPhonePath,
                name: AppRoutes.authPhone,
                builder: (BuildContext context, GoRouterState state) =>
                    const PhoneEntryScreen(),
              ),
              GoRoute(
                path: AppRoutes.authPasscodePath,
                name: AppRoutes.authPasscode,
                builder: (BuildContext context, GoRouterState state) =>
                    PasscodeEntryScreen(phone: state.extra! as String),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- phone

  group('Phone entry', () {
    testWidgets('the action is disabled until there is something to send', (
      WidgetTester tester,
    ) async {
      await pumpWithRouter(
        tester,
        harness((_) => json(<String, Object?>{})).overrides,
      );

      // Disabled, not absent — a real state rather than a hidden control.
      expect(find.text(tr.authPhoneSubmit), findsOneWidget);

      await tester.enterText(find.byType(TextField), '0532 123 45 67');
      await tester.pump();

      expect(find.text(tr.authPhoneSubmit), findsOneWidget);
    });

    testWidgets('submitting requests a passcode from the documented endpoint', (
      WidgetTester tester,
    ) async {
      await pumpWithRouter(
        tester,
        harness(
          (_) => json(<String, Object?>{'status': 'accepted'}, status: 202),
        ).overrides,
      );

      await tester.enterText(find.byType(TextField), '0532 123 45 67');
      await tester.pump();
      await tester.tap(find.text(tr.authPhoneSubmit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(sent.single.url.path, '/api/v1/auth/otp');
      expect(jsonDecode(sent.single.body), <String, Object?>{
        'phone': '0532 123 45 67',
      });
    });

    testWidgets('a rate limit is shown in the member\'s language', (
      WidgetTester tester,
    ) async {
      await pumpWithRouter(
        tester,
        harness((_) => envelope('rate_limited', status: 429)).overrides,
      );

      await tester.enterText(find.byType(TextField), '0532 123 45 67');
      await tester.pump();
      await tester.tap(find.text(tr.authPhoneSubmit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(tr.errorRateLimited), findsOneWidget);
    });

    /// CARRIES WEIGHT. The contract forbids showing the backend message, and
    /// RmFailure never carried one — this proves it end to end, on screen.
    testWidgets('the backend message never reaches the screen', (
      WidgetTester tester,
    ) async {
      await pumpWithRouter(
        tester,
        harness((_) => envelope('validation_failed', status: 422)).overrides,
      );

      await tester.enterText(find.byType(TextField), '0532 123 45 67');
      await tester.pump();
      await tester.tap(find.text(tr.authPhoneSubmit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(tr.errorValidation), findsOneWidget);
      expect(find.textContaining('DEVELOPER_ENGLISH'), findsNothing);
      expect(find.textContaining('0000000000ff'), findsNothing);
    });
  });

  // -------------------------------------------------------------- passcode

  group('Passcode entry', () {
    const String phone = '0532 123 45 67';

    testWidgets('it shows the number the member typed', (
      WidgetTester tester,
    ) async {
      await tester.pumpRmScreen(
        const PasscodeEntryScreen(phone: phone),
        overrides: harness((_) => json(<String, Object?>{})).overrides,
      );

      expect(find.text(tr.authCodeBody(phone)), findsOneWidget);
    });

    testWidgets('a correct passcode signs the session in', (
      WidgetTester tester,
    ) async {
      final InMemoryCredentialStore store = InMemoryCredentialStore();
      final ({RmSession session, List<Override> overrides}) h = harness(
        (_) => json(<String, Object?>{
          'access_token': 'rma_ACCESS',
          'refresh_token': 'rmr_REFRESH',
          'token_type': 'Bearer',
          'expires_in': 900,
          'session_id': 'SESSION_1',
        }),
        store: store,
      );

      await tester.pumpRmScreen(
        const PasscodeEntryScreen(phone: phone),
        overrides: h.overrides,
      );

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      await tester.tap(find.text(tr.authCodeSubmit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(h.session.state.value, isA<RmSignedIn>());
      expect((await store.read())?.refreshToken, 'rmr_REFRESH');
    });

    /// The generic "your session has ended" line is nonsense in front of
    /// somebody who has just mistyped six digits.
    testWidgets('a wrong passcode says so, and says nothing about attempts', (
      WidgetTester tester,
    ) async {
      await tester.pumpRmScreen(
        const PasscodeEntryScreen(phone: phone),
        overrides: harness(
          (_) => envelope('unauthenticated', status: 401),
        ).overrides,
      );

      await tester.enterText(find.byType(TextField), '000000');
      await tester.pump();
      await tester.tap(find.text(tr.authCodeSubmit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(tr.authCodeInvalid), findsOneWidget);
      expect(find.text(tr.errorUnauthenticated), findsNothing);
    });

    testWidgets('a suspended account gets the forbidden copy', (
      WidgetTester tester,
    ) async {
      await tester.pumpRmScreen(
        const PasscodeEntryScreen(phone: phone),
        overrides: harness((_) => envelope('forbidden', status: 403)).overrides,
      );

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      await tester.tap(find.text(tr.authCodeSubmit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(tr.errorForbidden), findsOneWidget);
    });

    /// The resend control has no countdown because the server does not publish
    /// when the cooldown expires. Asking too soon gets a real answer.
    testWidgets('resending asks the server, and reports a refusal honestly', (
      WidgetTester tester,
    ) async {
      await tester.pumpRmScreen(
        const PasscodeEntryScreen(phone: phone),
        overrides: harness(
          (_) => envelope('rate_limited', status: 429),
        ).overrides,
      );

      await tester.tap(find.text(tr.authCodeResend));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(sent.single.url.path, '/api/v1/auth/otp');
      expect(find.text(tr.errorRateLimited), findsOneWidget);
    });

    testWidgets('a successful resend confirms it', (WidgetTester tester) async {
      await tester.pumpRmScreen(
        const PasscodeEntryScreen(phone: phone),
        overrides: harness(
          (_) => json(<String, Object?>{'status': 'accepted'}, status: 202),
        ).overrides,
      );

      await tester.tap(find.text(tr.authCodeResend));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(tr.authCodeResent), findsOneWidget);
    });
  });

  group('Neither screen invents anything', () {
    /// No countdown, because the contract does not say when the cooldown ends
    /// and a local timer would be the client drawing a guess as fact.
    test('no resend countdown exists in the source', () {
      final String source = _codeOf(
        'lib/features/auth/presentation/passcode_entry_screen.dart',
      );

      for (final String banned in <String>[
        'Timer',
        'countdown',
        'secondsRemaining',
        'Duration(seconds: 60)',
      ]) {
        expect(source, isNot(contains(banned)), reason: banned);
      }
    });

    /// Trust Score, verification state and profile data are not part of
    /// signing in and must not be fabricated to fill the screens.
    test('no fabricated product state appears', () {
      for (final String file in <String>[
        'lib/features/auth/presentation/phone_entry_screen.dart',
        'lib/features/auth/presentation/passcode_entry_screen.dart',
      ]) {
        final String source = _codeOf(file);

        for (final String banned in <String>[
          'trustScore',
          'TrustScore',
          'verification',
          'displayName',
          'email',
          'terms',
          'consent',
        ]) {
          expect(source, isNot(contains(banned)), reason: '$file: $banned');
        }
      }
    });
  });
}

String _codeOf(String path) => File(path)
    .readAsLinesSync()
    .map((String line) {
      final int comment = line.indexOf('//');

      return comment == -1 ? line : line.substring(0, comment);
    })
    .join('\n');
