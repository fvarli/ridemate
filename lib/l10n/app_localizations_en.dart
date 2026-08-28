// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RideMate';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'Profile';

  @override
  String get navCreateRoute => 'Create route';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonBack => 'Back';

  @override
  String get commonClose => 'Close';

  @override
  String get commonLoading => 'Loading';

  @override
  String unitDistanceKm(String value) {
    return '$value km';
  }

  @override
  String unitDurationMinutes(String value) {
    return '$value min';
  }

  @override
  String unitDurationApproxMinutes(String value) {
    return '~$value min';
  }

  @override
  String get onboardingHeadlineBefore => 'Travel ';

  @override
  String get onboardingHeadlineEmphasis => 'safely';

  @override
  String get onboardingHeadlineAfter => ' with people going your way';

  @override
  String get onboardingSubtitle =>
      'With verified neighbours, colleagues and students. Not a taxi — a community.';

  @override
  String onboardingSocialProof(String count) {
    return '$count verified members in Istanbul';
  }

  @override
  String get onboardingCreateAccount => 'Create account';

  @override
  String get onboardingSignIn => 'I\'m already a member';

  @override
  String get verificationTitle => 'Identity verification';

  @override
  String get verificationScoreCaption => 'SCORE';

  @override
  String get verificationHeroTitle => 'Your Trust Score is building';

  @override
  String verificationHeroSubtitleBefore(String count) {
    return 'Complete $count more steps to earn the ';
  }

  @override
  String get verificationHeroSubtitleEmphasis => 'Verified';

  @override
  String get verificationHeroSubtitleAfter => ' badge.';

  @override
  String get verificationHeroComplete => 'All required steps are complete.';

  @override
  String get verificationStepPhone => 'Phone number';

  @override
  String get verificationStepEmail => 'Email address';

  @override
  String get verificationStepIdentity => 'ID (national ID / passport)';

  @override
  String get verificationStepSelfie => 'Selfie match';

  @override
  String get verificationStepLicence => 'Driving licence';

  @override
  String get verificationStepLicenceQualifier => ' · if you drive';

  @override
  String verificationStatusVerifiedWithDetail(String detail) {
    return 'Verified · $detail';
  }

  @override
  String get verificationStatusVerified => 'Verified';

  @override
  String verificationStatusInProgress(String minutes) {
    return 'Processing · ~$minutes min';
  }

  @override
  String get verificationStatusPending => 'Waiting';

  @override
  String get verificationStatusOptional => 'Optional';

  @override
  String get verificationUpload => 'Upload';

  @override
  String get homeGreeting => 'Good morning,';

  @override
  String get homeSearchPlaceholder => 'Where are you going?';

  @override
  String get homeSearchAction => 'Search';

  @override
  String get homeSearchSemanticLabel => 'Where are you going? Search routes.';

  @override
  String get homeShortcutHome => 'Home';

  @override
  String get homeShortcutWork => 'Work · Levent';

  @override
  String get homeShortcutUniversity => 'University';

  @override
  String get homeNearbyRoutesTitle => 'Routes near you';

  @override
  String homeMatchCount(String count) {
    return '$count matches →';
  }

  @override
  String homeMatchSemanticLabel(
    String name,
    String rating,
    String route,
    String costShare,
    String compatibility,
  ) {
    return '$name, rated $rating. $route. $costShare per person. $compatibility route match.';
  }

  @override
  String homeCompatibility(String value) {
    return '$value match';
  }

  @override
  String get searchTitle => 'Search routes';

  @override
  String get searchFieldOriginLabel => 'FROM';

  @override
  String get searchFieldDestinationLabel => 'TO';

  @override
  String get searchSwapSemanticLabel => 'Swap origin and destination';

  @override
  String get searchWhenLabel => 'WHEN';

  @override
  String get searchWhenValue => 'Tomorrow · 08:30';

  @override
  String get searchSeatsLabel => 'SEATS';

  @override
  String searchSeatsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get searchFiltersTitle => 'TRUST FILTERS';

  @override
  String get searchFilterVerifiedOnly => 'Verified only';

  @override
  String get searchFilterMinRating => '4.5+ rating';

  @override
  String get searchFilterFemaleDriver => 'Female driver';

  @override
  String get searchFilterNoSmoking => 'No smoking';

  @override
  String get searchFilterMutualConnection => 'Mutual connection';

  @override
  String get searchRecentTitle => 'RECENT SEARCHES';

  @override
  String searchSubmit(String count) {
    return 'See matches · $count results';
  }

  @override
  String get searchPlacePickerOriginTitle => 'Where are you starting?';

  @override
  String get searchPlacePickerDestinationTitle => 'Where are you going?';

  @override
  String matchesTitle(String count) {
    return '$count matches';
  }

  @override
  String matchesSubtitle(String route, String when) {
    return '$route · $when';
  }

  @override
  String get matchesWhenSummary => 'Tomorrow 08:30';

  @override
  String get matchesSortBest => 'Best match';

  @override
  String get matchesSortNearest => 'Nearest';

  @override
  String get matchesSortCheapest => 'Lowest share';

  @override
  String get matchesCompatibilityLabel => 'Route match';

  @override
  String get matchesInspect => 'View';

  @override
  String get matchesMetaVerified => 'Verified';

  @override
  String matchesMetaTrips(String count) {
    return '$count trips';
  }

  @override
  String matchesMetaSharedRoutes(String count) {
    return '$count shared routes';
  }

  @override
  String matchesMetaDeparture(String time) {
    return 'Departs $time';
  }

  @override
  String matchesMetaSeats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seats',
      one: '1 seat',
    );
    return '$_temp0';
  }

  @override
  String matchesMetaWalk(String minutes) {
    return '~$minutes min walk';
  }

  @override
  String matchesMetaCompatibilityShort(String value) {
    return '$value match';
  }

  @override
  String matchesCardSemanticLabel(
    String name,
    String rating,
    String compatibility,
    String time,
    String costShare,
  ) {
    return '$name, rated $rating. $compatibility route match. Departs $time. $costShare per person.';
  }

  @override
  String get routeDetailsStatTrustScore => 'Trust Score';

  @override
  String get routeDetailsStatApprovalRate => 'Approval rate';

  @override
  String get routeDetailsStatSharedDistance => 'km shared';

  @override
  String routeDetailsMemberSince(String year, String area) {
    return 'Member since $year · $area';
  }

  @override
  String routeDetailsRatingSummary(String rating, String trips) {
    return '$rating · $trips trips';
  }

  @override
  String get routeDetailsPickupLabel => 'Pickup point';

  @override
  String routeDetailsArrivalLabel(String minutes) {
    return 'Arrival · $minutes min';
  }

  @override
  String get routeDetailsMutualTitle => 'Mutual connection';

  @override
  String get routeDetailsCostShareLabel => 'Your share';

  @override
  String get routeDetailsMessageSemanticLabel => 'Message the driver';

  @override
  String get routeDetailsRequestSeat => 'Send request';

  @override
  String get routeDetailsRequestUnavailable => 'Trip requests are coming soon.';

  @override
  String get routeDetailsNotFound => 'This route is no longer available.';

  @override
  String get createRouteTitle => 'Create route';

  @override
  String get createRouteSubtitle => 'Share a seat as a driver';

  @override
  String createRouteOriginSemanticLabel(String place) {
    return 'From: $place';
  }

  @override
  String createRouteDestinationSemanticLabel(String place) {
    return 'To: $place';
  }

  @override
  String get createRouteOriginPickerTitle => 'Where are you starting?';

  @override
  String get createRouteDestinationPickerTitle => 'Where are you going?';

  @override
  String get createRouteOriginEmpty => 'Choose a pickup point';

  @override
  String get createRouteDestinationEmpty => 'Choose a destination';

  @override
  String get createRouteEndpointsSame =>
      'Pickup and destination cannot be the same place.';

  @override
  String get createRoutePlacesLoading => 'Loading places…';

  @override
  String get createRoutePlacesEmpty => 'No places are supported yet.';

  @override
  String get createRoutePlacesUnavailable =>
      'The place list could not be loaded.';

  @override
  String get createRouteRecurrenceTitle => 'Repeat every weekday';

  @override
  String get createRouteRecurrenceDetail => 'Mon–Fri';

  @override
  String get createRouteSeatsLabel => 'FREE SEATS';

  @override
  String get createRouteSeatsSemanticLabel => 'Free seats';

  @override
  String createRouteSeatsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seats',
      one: '1 seat',
    );
    return '$_temp0';
  }

  @override
  String get createRouteDepartureDateLabel => 'DEPARTURE DATE';

  @override
  String get createRouteDepartureDateEmpty => 'Choose a date';

  @override
  String get createRouteDepartureTimeLabel => 'DEPARTURE TIME';

  @override
  String get createRouteDepartureTimeEmpty => 'Choose a time';

  @override
  String get createRouteDepartureDateMissing => 'Choose a departure date.';

  @override
  String get createRouteDepartureTimeMissing => 'Choose a departure time.';

  @override
  String get createRoutePublished => 'Your route is published.';

  @override
  String get createRoutePublishFailed => 'The route could not be published.';

  @override
  String get createRouteRulesTitle => 'RIDE RULES';

  @override
  String get createRouteRuleNoSmoking => 'No smoking';

  @override
  String get createRouteRuleMusicOk => 'Music OK';

  @override
  String get createRouteRuleNoPets => 'No pets';

  @override
  String get createRouteRuleQuiet => 'Quiet';

  @override
  String get createRoutePublish => 'Publish route';

  @override
  String get activeTripLiveBadge => 'LIVE TRIP';

  @override
  String get activeTripEtaLabel => 'Arriving in Levent';

  @override
  String activeTripEtaValue(String duration, String distance) {
    return '$duration $distance';
  }

  @override
  String get activeTripOnTime => 'On time';

  @override
  String activeTripEtaSemanticLabel(
    String label,
    String duration,
    String distance,
    String status,
  ) {
    return '$label, $duration, $distance, $status';
  }

  @override
  String activeTripDriverSemanticLabel(
    String name,
    String rating,
    String vehicle,
    String plate,
  ) {
    return '$name, rated $rating, online. $vehicle, $plate.';
  }

  @override
  String activeTripDriverMeta(String vehicle, String plate) {
    return '$vehicle · $plate';
  }

  @override
  String activeTripDriverName(String name, String rating) {
    return '$name · $rating';
  }

  @override
  String get activeTripCall => 'Call the driver';

  @override
  String get activeTripMessage => 'Message the driver';

  @override
  String get activeTripShare => 'Share trip';

  @override
  String get sosLabel => 'SOS';

  @override
  String activeTripLocationSharing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your live location is shared with $count emergency contacts',
      one: 'Your live location is shared with 1 emergency contact',
    );
    return '$_temp0';
  }

  @override
  String get activeTripShareUnavailable =>
      'Trip sharing is not active yet. Nothing was shared.';

  @override
  String get activeTripCallUnavailable =>
      'Calling is not active yet. No call was started.';

  @override
  String get sosUnavailable =>
      'Emergency features are not active yet. Nobody was notified.';

  @override
  String get chatOnline => 'Online';

  @override
  String chatHeaderSemanticLabel(String name) {
    return '$name, identity verified, online';
  }

  @override
  String get chatSafetyBanner =>
      'Payments are not available yet. Do not share personal or financial information.';

  @override
  String get chatMessageIncoming =>
      'Hi Elif! I\'ll be at Kadıköy İskele at 08:25 tomorrow 👍';

  @override
  String get chatMessageOutgoing => 'Great, thank you! I\'ll be there too.';

  @override
  String get chatMessageOutgoingClosing => 'See you 🙌';

  @override
  String get chatLocationLabel => '📍 Meeting point';

  @override
  String chatLocationSemanticLabel(String name, String label) {
    return '$name shared a location: $label';
  }

  @override
  String chatBubbleSemanticLabel(String speaker, String text) {
    return '$speaker: $text';
  }

  @override
  String get chatSpeakerSelf => 'You';

  @override
  String get chatQuickReplyOnMyWay => 'On my way';

  @override
  String get chatQuickReplyRunningLate => '5 min late';

  @override
  String get chatComposerHint => 'Write a message…';

  @override
  String get chatComposerLabel => 'Write your message';

  @override
  String get chatSend => 'Send';

  @override
  String get chatSendUnavailable =>
      'Message was not sent. Messaging is not available yet.';

  @override
  String get profileMemberBadge => 'Verified member · since 2024';

  @override
  String get profileTrustScoreTitle => 'Trust Score';

  @override
  String get profileTrustScoreOutOf => '/ 100';

  @override
  String profileTrustTier(String percentile) {
    return 'Top $percentile · Trusted';
  }

  @override
  String get profileTrustNextStep => '1 more journey to reach 100';

  @override
  String get profileTrustFactorIdentity => 'Identity';

  @override
  String get profileTrustFactorCommunity => 'Community';

  @override
  String get profileTrustFactorReliability => 'Reliability';

  @override
  String get profileTrustFactorActivity => 'Activity';

  @override
  String get profileStatTrips => 'Journeys';

  @override
  String get profileStatRating => 'Rating';

  @override
  String get profileStatSavings => 'Saved';

  @override
  String get profileVerificationBadges => 'Verification badges';

  @override
  String get profileMyReviews => 'My reviews';

  @override
  String profileTrustScoreSemanticLabel(String score) {
    return 'Trust Score: $score out of 100';
  }

  @override
  String profileTrustFactorSemanticLabel(String label, String value) {
    return '$label: $value';
  }

  @override
  String profileTrustFactorAttentionSemanticLabel(String label, String value) {
    return '$label: $value, needs attention';
  }

  @override
  String profileVerificationBadgesSemanticLabel(String done, String total) {
    return 'Verification badges: $done of $total steps complete';
  }

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String reviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get reviewsTagPunctual => 'Punctual';

  @override
  String get reviewsTagSafeDriving => 'Safe driving';

  @override
  String get reviewsTagFriendly => 'Friendly';

  @override
  String get reviewsTagCleanCar => 'Clean car';

  @override
  String reviewsTagLabel(String label, String count) {
    return '$label · $count';
  }

  @override
  String get reviewsContextRegularRoute => 'Regular route';

  @override
  String get reviewsMockBodyFirst =>
      'A very safe and punctual journey. Selin is genuinely friendly — I would absolutely ride again.';

  @override
  String get reviewsMockBodySecond =>
      'Same time every morning, spotless car. Nice to chat in the traffic.';

  @override
  String reviewsRatingSemanticLabel(String rating) {
    return '$rating out of 5';
  }

  @override
  String reviewsDistributionSemanticLabel(String stars, String share) {
    return '$stars stars: $share of reviews';
  }

  @override
  String reviewsEntrySemanticLabel(
    String author,
    String age,
    String context,
    String rating,
    String body,
  ) {
    return '$author, $age, $context. $rating. $body';
  }

  @override
  String get safetyTitle => 'Safety Center';

  @override
  String get safetySubtitle => 'With you on every journey';

  @override
  String get safetySosTitle => 'Emergency help';

  @override
  String get safetySosPromise =>
      'Press, and your location and journey details go to your emergency contacts + our team.';

  @override
  String get safetyCallEmergencyTitle => 'Call 112';

  @override
  String get safetyCallEmergencyCaption => 'Emergency services';

  @override
  String get safetyShareTripTitle => 'Share trip';

  @override
  String get safetyShareTripCaption => 'Live location';

  @override
  String safetyQuickActionSemanticLabel(String title, String caption) {
    return '$title. $caption';
  }

  @override
  String get safetyTrustedContactsTitle => 'Trusted contacts';

  @override
  String safetyTrustedContactsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people added',
      one: '1 person added',
    );
    return '$_temp0';
  }

  @override
  String get safetyVerifyPartnerTitle => 'Verify your travel partner';

  @override
  String get safetyVerifyPartnerSubtitle => 'Match identity by QR';

  @override
  String get safetyBlockReportTitle => 'Block / report a member';

  @override
  String get safetyBlockReportSubtitle => 'Confidential review';

  @override
  String get safetyCallUnavailable => 'The app cannot start phone calls yet.';

  @override
  String get safetyTrustedContactsUnavailable =>
      'Trusted contacts are not available yet.';

  @override
  String get safetyVerifyPartnerUnavailable =>
      'QR verification is not available yet.';

  @override
  String get safetyBlockReportUnavailable =>
      'Blocking a member is not available yet.';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get errorBody =>
      'This page could not be opened. You can go back to the home screen and try again.';

  @override
  String get errorReturnHome => 'Back to home';

  @override
  String get messagesPlaceholderBody =>
      'The conversation list is not available yet.';

  @override
  String get homeShortcutUnavailable =>
      'Saved addresses are not available yet.';

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String get dateTomorrow => 'Tomorrow';

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String get errorNetwork =>
      'Couldn\'t connect. Check your internet connection.';

  @override
  String get errorConflict =>
      'This route appears to have been published already.';

  @override
  String get errorUnexpected => 'Something went wrong. Please try again.';

  @override
  String get errorValidation => 'Check the details you entered.';

  @override
  String get errorUnauthenticated => 'Your session has ended. Sign in again.';

  @override
  String get errorForbidden => 'Your account has been suspended.';

  @override
  String get errorRateLimited => 'Too many attempts. Try again shortly.';

  @override
  String get authPhoneTitle => 'Your phone number';

  @override
  String get authPhoneBody => 'We\'ll send you a six-digit verification code.';

  @override
  String get authPhoneFieldLabel => 'Phone number';

  @override
  String get authPhoneFieldHint => '0532 123 45 67';

  @override
  String get authPhoneInvalid => 'Enter a valid phone number.';

  @override
  String get authPhoneSubmit => 'Send code';

  @override
  String get authCodeTitle => 'Verification code';

  @override
  String authCodeBody(String phone) {
    return 'Enter the code sent to $phone.';
  }

  @override
  String get authCodeFieldLabel => 'Six-digit code';

  @override
  String get authCodeInvalid => 'That code isn\'t right. Try again.';

  @override
  String get authCodeSubmit => 'Verify';

  @override
  String get authCodeResend => 'Send a new code';

  @override
  String get authCodeResent => 'A new code has been sent.';
}
