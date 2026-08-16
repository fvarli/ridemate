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
  String get onboardingSignInUnavailable => 'Sign-in is coming soon.';

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
    String fare,
    String compatibility,
  ) {
    return '$name, rated $rating. $route. $fare per person. $compatibility route match.';
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
    String fare,
  ) {
    return '$name, rated $rating. $compatibility route match. Departs $time. $fare per person.';
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
  String get routeDetailsFareLabel => 'Your share';

  @override
  String get routeDetailsMessageSemanticLabel => 'Message the driver';

  @override
  String get routeDetailsRequestSeat => 'Send request';

  @override
  String get routeDetailsRequestUnavailable => 'Trip requests are coming soon.';

  @override
  String get routeDetailsMessagingUnavailable => 'Messaging is coming soon.';

  @override
  String get routeDetailsNotFound => 'This route is no longer available.';

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
}
