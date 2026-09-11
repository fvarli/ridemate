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
  String matchesMetaSharedRoutes(String count) {
    return '$count shared routes';
  }

  @override
  String get discoveryTitle => 'Journeys';

  @override
  String get searchSubmit => 'Search journeys';

  @override
  String get searchIncomplete => 'Choose two different places.';

  @override
  String get discoveryIdle => 'Choose where you\'re travelling between.';

  @override
  String get discoveryEmpty =>
      'No published journeys between these two places.';

  @override
  String get discoveryEmptyBody => 'Check back later, or try another route.';

  @override
  String get discoveryOrdering => 'Most recently published first';

  @override
  String discoverySeatsOffered(int count) {
    return '$count seats offered';
  }

  @override
  String get discoveryLoadMore => 'Show more';

  @override
  String get discoveryLoadMoreFailed => 'Couldn\'t load more.';

  @override
  String get seatRequestAsk => 'Request a seat';

  @override
  String get seatRequestSending => 'Sending…';

  @override
  String get seatRequestPending => 'Request sent';

  @override
  String get seatRequestAccepted => 'Accepted';

  @override
  String get seatRequestDeclined => 'Declined';

  @override
  String get seatRequestWithdrawn => 'Withdrawn';

  @override
  String get seatRequestFailed => 'The request was not sent';

  @override
  String get seatRequestRecurringUnsupported =>
      'Requests for recurring journeys are not available yet';

  @override
  String get seatRequestOwnRoute => 'This is your journey';

  @override
  String get seatRequestRouteFull => 'Every offered seat has been given';

  @override
  String get seatRequestUnavailable => 'This journey is no longer available';

  @override
  String get myRequestsTitle => 'My requests';

  @override
  String get myRequestsSubtitle => 'Most recently sent first';

  @override
  String get myRequestsEmpty => 'You have not requested a seat yet';

  @override
  String get myRequestsEmptyBody =>
      'Find a journey and request a seat, and it will appear here.';

  @override
  String get myRequestsLoadMore => 'Show more';

  @override
  String get myRequestsLoadMoreFailed =>
      'The next requests could not be loaded';

  @override
  String get myRequestsWithdraw => 'Withdraw request';

  @override
  String get myRequestsWithdrawn => 'Request withdrawn';

  @override
  String get myRequestsWithdrawFailed => 'The request could not be withdrawn';

  @override
  String get myRequestsRouteCancelled => 'This journey was cancelled';

  @override
  String get myRequestsRouteDeparted => 'This journey has departed';

  @override
  String get myRequestsOpen => 'My requests';

  @override
  String get routeRequestsOpen => 'Requests';

  @override
  String routeRequestsOpenSemanticLabel(String journey) {
    return 'Incoming requests for $journey';
  }

  @override
  String get routeRequestsTitle => 'Incoming requests';

  @override
  String get routeRequestsEmpty => 'No requests for this journey yet';

  @override
  String get routeRequestsEmptyBody =>
      'When somebody requests a seat, it appears here.';

  @override
  String get routeRequestsLoadMore => 'Show more';

  @override
  String get routeRequestsLoadMoreFailed =>
      'The next requests could not be loaded';

  @override
  String get routeRequestsAccept => 'Accept';

  @override
  String get routeRequestsDecline => 'Decline';

  @override
  String routeRequestsAcceptSemanticLabel(String passenger) {
    return 'Accept $passenger\'s request';
  }

  @override
  String routeRequestsDeclineSemanticLabel(String passenger) {
    return 'Decline $passenger\'s request';
  }

  @override
  String get routeRequestsAccepted => 'Request accepted';

  @override
  String get routeRequestsDeclined => 'Request declined';

  @override
  String get routeRequestsFull => 'Every offered seat has been given';

  @override
  String get routeRequestsRouteUnavailable =>
      'This journey is no longer available';

  @override
  String get routeRequestsDecisionFailed => 'The request could not be answered';

  @override
  String discoveryCardSemanticLabel(
    String driver,
    String journey,
    String departure,
    String seats,
  ) {
    return '$driver, $journey, $departure, $seats';
  }

  @override
  String get searchPlacePickerOriginTitle => 'Where are you starting?';

  @override
  String get searchPlacePickerDestinationTitle => 'Where are you going?';

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
  String get profileMyReviews => 'My reviews';

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
  String get profileSetupTitle => 'What should we call you?';

  @override
  String get profileSetupBody =>
      'This name is shown to the people you share journeys with.';

  @override
  String get profileSetupFieldLabel => 'Your name';

  @override
  String get profileSetupFieldHint => 'Ayşe Demir';

  @override
  String get profileSetupSubmit => 'Continue';

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

  @override
  String get myRoutesTitle => 'My routes';

  @override
  String get profileEditName => 'Edit your name';

  @override
  String get profileEditSave => 'Save';

  @override
  String get profileNoProfileYet => 'You haven\'t chosen a name yet.';

  @override
  String get profileMyRoutes => 'My routes';

  @override
  String myRoutesSeatsOffered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'offering $count seats',
      one: 'offering 1 seat',
    );
    return '$_temp0';
  }

  @override
  String get myRoutesRecurrenceWeekdays => 'Every weekday';

  @override
  String get myRoutesStatusPublished => 'Published';

  @override
  String get myRoutesStatusCancelled => 'Cancelled';

  @override
  String get myRoutesStatusPast => 'Past';

  @override
  String get myRoutesEmptyTitle => 'You haven\'t published a route yet';

  @override
  String get myRoutesEmptyBody => 'The routes you publish will appear here.';

  @override
  String get myRoutesLoadMore => 'Load more';

  @override
  String get myRoutesLoadMoreFailed => 'Couldn\'t load the next page.';

  @override
  String get myRoutesCancel => 'Cancel route';

  @override
  String get myRoutesCancelConfirmTitle => 'Cancel this route?';

  @override
  String myRoutesCancelConfirmBody(String route) {
    return '$route will be withdrawn. It stays in your history.';
  }

  @override
  String get myRoutesCancelConfirm => 'Yes, cancel it';

  @override
  String get myRoutesCancelDismiss => 'Keep it';

  @override
  String get myRoutesCancelled => 'The route is cancelled.';

  @override
  String get myRoutesTripStateNotStarted => 'Trip: Not started';

  @override
  String get myRoutesTripStateInProgress => 'Trip: Started';

  @override
  String get myRoutesTripStateCompleted => 'Trip: Completed';

  @override
  String get myRoutesTripStateAborted => 'Trip: Abandoned';

  @override
  String get myRoutesStartTrip => 'Start trip';

  @override
  String myRoutesStartTripSemanticLabel(String route) {
    return 'Start the trip for $route';
  }

  @override
  String myRoutesTripStarted(String route) {
    return 'The trip for $route has started.';
  }

  @override
  String get myRoutesCompleteTrip => 'Complete trip';

  @override
  String myRoutesCompleteTripSemanticLabel(String route) {
    return 'Complete the trip for $route';
  }

  @override
  String get myRoutesAbortTrip => 'Abandon trip';

  @override
  String myRoutesAbortTripSemanticLabel(String route) {
    return 'Abandon the trip for $route';
  }

  @override
  String myRoutesTripCompleted(String route) {
    return 'The trip for $route is complete.';
  }

  @override
  String myRoutesTripAborted(String route) {
    return 'The trip for $route was abandoned.';
  }

  @override
  String get myRoutesTripNotStarted => 'This trip has not been started.';

  @override
  String get myRoutesStartDepartureNotReached =>
      'This trip cannot be started yet.';

  @override
  String get myRoutesStartRecurringUnsupported =>
      'Starting a trip on a recurring route is not supported yet.';

  @override
  String get myRoutesStartRouteUnavailable =>
      'This route can no longer be started.';

  @override
  String get myRoutesTripAlreadyCompleted => 'This trip was already completed.';

  @override
  String get myRoutesTripAlreadyAborted => 'This trip was already abandoned.';

  @override
  String myRoutesCardSemanticLabel(
    String route,
    String departure,
    String seats,
    String status,
    String trip,
  ) {
    return '$route, $departure, $seats, $status, $trip';
  }

  @override
  String myRoutesCancelSemanticLabel(String route) {
    return 'Cancel the $route route';
  }

  @override
  String get tripStatusTitle => 'Trip status';

  @override
  String get tripStatusDeparture => 'Scheduled departure';

  @override
  String get tripStatusState => 'State';

  @override
  String get tripStatusStateNotStarted => 'Not started';

  @override
  String get tripStatusStateInProgress => 'Started';

  @override
  String get tripStatusStateCompleted => 'Completed';

  @override
  String get tripStatusStateAborted => 'Abandoned';

  @override
  String get tripStatusStartedNote =>
      'This only means you started the trip in RideMate. No location, map, navigation or passenger information is held.';

  @override
  String get tripStatusStartedAt => 'Started at';

  @override
  String get tripStatusCompletedAt => 'Completed at';

  @override
  String get tripStatusAbortedAt => 'Abandoned at';

  @override
  String get tripStatusNotFound => 'This route is not in your list';

  @override
  String get tripStatusNotFoundBody => 'Reload your routes and try again.';
}
