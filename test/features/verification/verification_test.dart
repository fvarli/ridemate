import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/core/widgets/rm_meters.dart';
import 'package:ridemate/features/verification/application/verification_controller.dart';
import 'package:ridemate/features/verification/domain/mock_verification_scenarios.dart';
import 'package:ridemate/features/verification/domain/verification_state.dart';
import 'package:ridemate/features/verification/presentation/verification_screen.dart';
import 'package:ridemate/features/verification/presentation/widgets/verification_step_row.dart';

import '../../support/pump.dart';

void main() {
  group('Mock scenarios reproduce the approved design', () {
    test('the first scenario matches the design source exactly', () {
      const VerificationState s = MockVerificationScenarios.initial;

      expect(s.displayTrustScore, 60);
      expect(s.steps.length, 5);
      expect(s.steps[0].status, VerificationStepStatus.verified);
      expect(s.steps[1].status, VerificationStepStatus.verified);
      expect(s.steps[2].status, VerificationStepStatus.inProgress);
      expect(s.steps[3].status, VerificationStepStatus.pending);
      expect(s.steps[4].status, VerificationStepStatus.optional);
      // The design copy reads "2 adım daha tamamla".
      expect(s.remainingRequiredSteps, 2);
      expect(s.allRequiredStepsVerified, isFalse);
    });

    test('the licence step is never required', () {
      for (final VerificationState s in MockVerificationScenarios.script) {
        final VerificationStep licence = s.steps.firstWhere(
          (VerificationStep e) => e.id == VerificationStepId.licence,
        );
        expect(licence.isRequired, isFalse);
        expect(licence.status, VerificationStepStatus.optional);
      }
    });

    test('the final scenario completes every required step', () {
      const VerificationState s = MockVerificationScenarios.allRequiredComplete;
      expect(s.allRequiredStepsVerified, isTrue);
      expect(s.remainingRequiredSteps, 0);
    });
  });

  group('The Trust Score is fixture data, never computed', () {
    test('each scenario carries its own display score', () {
      // The score is a value the state CARRIES. Nothing derives it, because
      // the real Trust Score is a backend-owned, safety-sensitive concept and
      // a design mock is not evidence of its formula.
      expect(
        MockVerificationScenarios.script
            .map((VerificationState s) => s.displayTrustScore)
            .toList(),
        <int>[60, 82, 100],
      );
    });

    test('the score cannot be reconstructed from the step list', () {
      // Two of five steps verified would be 40% under any step-count rule,
      // yet the approved design shows 60. Proof that no step-derived formula
      // reproduces the design, and therefore that none should exist.
      const VerificationState s = MockVerificationScenarios.initial;
      final int verified = s.steps
          .where(
            (VerificationStep e) => e.status == VerificationStepStatus.verified,
          )
          .length;

      expect(verified, 2);
      expect(
        s.displayTrustScore,
        isNot((verified / s.steps.length * 100).round()),
        reason: 'the design score is not a function of the step counts',
      );
    });

    test('a state renders whatever score it is given', () {
      // Constructing a state with an arbitrary score must be possible and must
      // not be "corrected" by any internal rule.
      const VerificationState s = VerificationState(
        displayTrustScore: 7,
        steps: <VerificationStep>[
          VerificationStep(
            id: VerificationStepId.phone,
            status: VerificationStepStatus.verified,
          ),
        ],
      );
      expect(s.displayTrustScore, 7);
      expect(s.allRequiredStepsVerified, isTrue);
    });
  });

  group('VerificationController', () {
    ProviderContainer container() {
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('starts on the design scenario', () {
      expect(
        container().read(verificationControllerProvider),
        MockVerificationScenarios.initial,
      );
    });

    test('advance walks the script and then stops', () {
      final ProviderContainer c = container();
      final VerificationController controller = c.read(
        verificationControllerProvider.notifier,
      );

      controller.advance();
      expect(
        c.read(verificationControllerProvider),
        MockVerificationScenarios.identityComplete,
      );

      controller.advance();
      expect(
        c.read(verificationControllerProvider),
        MockVerificationScenarios.allRequiredComplete,
      );

      // Terminal: further taps are a no-op rather than wrapping around.
      expect(controller.canAdvance, isFalse);
      controller.advance();
      expect(
        c.read(verificationControllerProvider),
        MockVerificationScenarios.allRequiredComplete,
      );
    });
  });

  group('VerificationScreen', () {
    Future<void> pump(
      WidgetTester tester, {
      Brightness brightness = Brightness.light,
      TextDirection textDirection = TextDirection.ltr,
      Locale locale = kDefaultTestLocale,
    }) async {
      await tester.pumpRmScreen(
        const VerificationScreen(),
        brightness: brightness,
        textDirection: textDirection,
        locale: locale,
        surfaceSize: const Size(393, 900),
      );
      await tester.pump();
    }

    testBothThemes('renders the approved copy and all four states', (
      WidgetTester tester,
      Brightness brightness,
    ) async {
      await pump(tester, brightness: brightness);

      expect(tester.takeException(), isNull);
      expect(find.text('Kimlik doğrulama'), findsOneWidget);
      expect(find.text('Güven Puanın oluşuyor'), findsOneWidget);
      // All five steps, verbatim.
      expect(find.text('Telefon numarası'), findsOneWidget);
      expect(find.text('E-posta adresi'), findsOneWidget);
      expect(find.text('Kimlik (T.C. / Pasaport)'), findsOneWidget);
      expect(find.text('Selfie eşleştirme'), findsOneWidget);
      expect(find.byType(VerificationStepRow), findsNWidgets(5));
      // The four distinct status lines.
      expect(find.text('Doğrulandı · +90 5•• ••• 42'), findsOneWidget);
      expect(find.text('Doğrulandı'), findsOneWidget);
      expect(find.text('İşleniyor · ~2 dk'), findsOneWidget);
      expect(find.text('Bekliyor'), findsOneWidget);
      expect(find.text('Opsiyonel'), findsOneWidget);
    });

    testWidgets('shows the fixture score, in the mono numeric style', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      expect(find.text('60'), findsOneWidget);
      expect(find.byType(RmTrustRing), findsOneWidget);
    });

    testWidgets('advancing follows the fixture, not a computed value', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      expect(find.text('60'), findsOneWidget);

      await tester.tap(find.text('Yükle'));
      await tester.pump();

      // 82 is the next scenario's declared display value.
      expect(
        find.text('82'),
        findsOneWidget,
        reason: 'the ring must follow the scenario fixture',
      );
      expect(find.text('60'), findsNothing);
    });

    testWidgets('completion changes only the copy — nothing navigates', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Yükle'));
      await tester.pump();
      await tester.tap(find.text('Yükle'));
      await tester.pump();

      expect(find.text('100'), findsOneWidget);
      expect(find.text('Tüm gerekli adımlar tamamlandı.'), findsOneWidget);
      // No success screen was invented and the screen did not move on.
      expect(find.byType(VerificationScreen), findsOneWidget);
      // The optional licence step is still offered, not auto-completed.
      expect(find.text('Opsiyonel'), findsOneWidget);
    });

    testWidgets('pending and optional stay distinct to a screen reader', (
      WidgetTester tester,
    ) async {
      // They look identical in the approved design; the semantics must not be.
      await pump(tester);

      expect(
        find.bySemanticsLabel('Selfie eşleştirme. Bekliyor'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Ehliyet. Opsiyonel'), findsOneWidget);
    });

    testWidgets('renders under RTL and in English without overflow', (
      WidgetTester tester,
    ) async {
      await pump(tester, textDirection: TextDirection.rtl);
      expect(tester.takeException(), isNull);

      await pump(tester, locale: const Locale('en'));
      expect(tester.takeException(), isNull);
      expect(find.text('Identity verification'), findsOneWidget);
    });
  });
}
