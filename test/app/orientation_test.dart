// ─────────────────────────────────────────────────────────────
// RideMate — Landscape smoke coverage
//
// RideMate is NOT orientation-locked, and this is the evidence for that
// decision rather than a note asserting it.
//
// The approved design is a portrait phone comp, which is a reason to design
// for portrait — not a reason to forbid landscape. Locking costs real people
// real access: a phone in a car mount is landscape, and members who cannot
// comfortably rotate a device rely on the system honouring the orientation
// they have chosen. Large-screen and foldable guidance points the same way.
// None of that is worth spending to avoid a layout the screens already handle,
// because every one of them scrolls.
//
// So the rule is: a screen that breaks in landscape is a responsive defect and
// gets reported as one. It is not an argument for a global lock.
//
// PUMP NOTE: Active Trip, Chat and the Safety Center animate forever, so they
// pump fixed frames rather than settling.
// ─────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/features/chat/presentation/chat_screen.dart';
import 'package:ridemate/features/create_route/presentation/create_route_screen.dart';
import 'package:ridemate/features/discovery/domain/mock_discovery_fixtures.dart';
import 'package:ridemate/features/discovery/presentation/match_results_screen.dart';
import 'package:ridemate/features/discovery/presentation/route_details_screen.dart';
import 'package:ridemate/features/discovery/presentation/search_screen.dart';
import 'package:ridemate/features/home/presentation/home_screen.dart';
import 'package:ridemate/features/onboarding/presentation/onboarding_screen.dart';
import 'package:ridemate/features/profile/presentation/profile_screen.dart';
import 'package:ridemate/features/reviews/presentation/reviews_screen.dart';
import 'package:ridemate/features/safety/presentation/safety_screen.dart';
import 'package:ridemate/features/trip/presentation/active_trip_screen.dart';
import 'package:ridemate/features/verification/presentation/verification_screen.dart';

import '../support/fonts.dart';
import '../support/pump.dart';

/// A phone rotated: the 393x852 portrait surface on its side.
const Size kLandscapePhone = Size(852, 393);

/// A short landscape surface, where vertical space is scarcest.
const Size kShortLandscape = Size(740, 360);

void main() {
  setUpAll(loadRideMateFonts);

  final Map<String, Widget> screens = <String, Widget>{
    'Onboarding': const OnboardingScreen(),
    'Verification': const VerificationScreen(),
    'Home': const Scaffold(body: HomeScreen()),
    'Search': const SearchScreen(),
    'Match results': const MatchResultsScreen(),
    'Route details': RouteDetailsScreen(routeId: MockRouteOffers.selin.id),
    'Create route': const CreateRouteScreen(),
    'Chat': const ChatScreen(),
    'Active trip': const ActiveTripScreen(),
    'Profile': const ProfileScreen(),
    'Reviews': const ReviewsScreen(),
    'Safety centre': const SafetyScreen(),
  };

  for (final Size size in <Size>[kLandscapePhone, kShortLandscape]) {
    group('Landscape ${size.width.toInt()}x${size.height.toInt()}', () {
      screens.forEach((String name, Widget screen) {
        testWidgets(name, (WidgetTester tester) async {
          await tester.pumpRmScreen(
            screen,
            surfaceSize: size,
            // Three screens never settle; a fixed frame works for all of them.
            disableAnimations: true,
          );
          await tester.pump(const Duration(milliseconds: 200));

          expect(
            tester.takeException(),
            isNull,
            reason:
                '$name overflows in landscape — a responsive defect, not '
                'a reason to lock orientation',
          );
        });
      });
    });
  }

  group('The orientation decision is not silently reversed', () {
    test('neither platform locks orientation', () {
      // Android: no android:screenOrientation on the activity.
      expect(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        isNot(contains('screenOrientation')),
      );

      // iOS: the generated set of supported orientations is left alone.
      final String plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(plist, contains('UIInterfaceOrientationLandscapeLeft'));
      expect(plist, contains('UIInterfaceOrientationLandscapeRight'));
    });

    test('nothing forces a preferred orientation at runtime', () {
      // SystemChrome.setPreferredOrientations would lock the app from Dart
      // and leave both platform manifests looking innocent.
      for (final FileSystemEntity entity in Directory(
        'lib',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        expect(
          entity.readAsStringSync(),
          isNot(contains('setPreferredOrientations')),
          reason: entity.path,
        );
      }
    });
  });
}
