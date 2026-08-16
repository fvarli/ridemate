import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/app/ride_mate_app.dart';

void main() {
  group('RideMateApp', () {
    testWidgets('boots and renders without exceptions', (tester) async {
      await tester.pumpWidget(const RideMateApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text(RideMateApp.appTitle), findsOneWidget);
    });

    testWidgets('does not show the debug banner', (tester) async {
      await tester.pumpWidget(const RideMateApp());

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, isFalse);
      expect(app.title, RideMateApp.appTitle);
    });

    testWidgets('renders in both light and dark platform brightness', (
      tester,
    ) async {
      for (final Brightness brightness in Brightness.values) {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(platformBrightness: brightness),
            child: const RideMateApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'RideMateApp threw under $brightness',
        );
      }
    });
  });
}
