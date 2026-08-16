// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'RideMate';

  @override
  String get navHome => 'Anasayfa';

  @override
  String get navSearch => 'Ara';

  @override
  String get navMessages => 'Mesajlar';

  @override
  String get navProfile => 'Profil';

  @override
  String get navCreateRoute => 'Rota oluştur';

  @override
  String get commonBack => 'Geri';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonLoading => 'Yükleniyor';

  @override
  String unitDistanceKm(String value) {
    return '$value km';
  }

  @override
  String unitDurationMinutes(String value) {
    return '$value dk';
  }

  @override
  String unitDurationApproxMinutes(String value) {
    return '~$value dk';
  }

  @override
  String get onboardingHeadlineBefore => 'Aynı yöne gidenlerle ';

  @override
  String get onboardingHeadlineEmphasis => 'güvenle';

  @override
  String get onboardingHeadlineAfter => ' yola çık';

  @override
  String get onboardingSubtitle =>
      'Doğrulanmış komşular, iş arkadaşları ve öğrencilerle. Taksi değil — topluluk.';

  @override
  String onboardingSocialProof(String count) {
    return '$count doğrulanmış üye İstanbul\'da';
  }

  @override
  String get onboardingCreateAccount => 'Hesap oluştur';

  @override
  String get onboardingSignIn => 'Zaten üyeyim';

  @override
  String get onboardingSignInUnavailable => 'Giriş özelliği yakında eklenecek.';

  @override
  String get verificationTitle => 'Kimlik doğrulama';

  @override
  String get verificationScoreCaption => 'PUAN';

  @override
  String get verificationHeroTitle => 'Güven Puanın oluşuyor';

  @override
  String verificationHeroSubtitleBefore(String count) {
    return '$count adım daha tamamla, ';
  }

  @override
  String get verificationHeroSubtitleEmphasis => 'Doğrulanmış';

  @override
  String get verificationHeroSubtitleAfter => ' rozetini kazan.';

  @override
  String get verificationHeroComplete => 'Tüm gerekli adımlar tamamlandı.';

  @override
  String get verificationStepPhone => 'Telefon numarası';

  @override
  String get verificationStepEmail => 'E-posta adresi';

  @override
  String get verificationStepIdentity => 'Kimlik (T.C. / Pasaport)';

  @override
  String get verificationStepSelfie => 'Selfie eşleştirme';

  @override
  String get verificationStepLicence => 'Ehliyet';

  @override
  String get verificationStepLicenceQualifier => ' · sürücüysen';

  @override
  String verificationStatusVerifiedWithDetail(String detail) {
    return 'Doğrulandı · $detail';
  }

  @override
  String get verificationStatusVerified => 'Doğrulandı';

  @override
  String verificationStatusInProgress(String minutes) {
    return 'İşleniyor · ~$minutes dk';
  }

  @override
  String get verificationStatusPending => 'Bekliyor';

  @override
  String get verificationStatusOptional => 'Opsiyonel';

  @override
  String get verificationUpload => 'Yükle';

  @override
  String get homeGreeting => 'Günaydın,';

  @override
  String get homeSearchPlaceholder => 'Nereye gidiyorsun?';

  @override
  String get homeSearchAction => 'Ara';

  @override
  String get homeSearchSemanticLabel => 'Nereye gidiyorsun? Rota ara.';

  @override
  String get homeShortcutHome => 'Ev';

  @override
  String get homeShortcutWork => 'İş · Levent';

  @override
  String get homeShortcutUniversity => 'Üniversite';

  @override
  String get homeNearbyRoutesTitle => 'Yakınındaki rotalar';

  @override
  String homeMatchCount(String count) {
    return '$count eşleşme →';
  }

  @override
  String homeMatchSemanticLabel(
    String name,
    String rating,
    String route,
    String fare,
    String compatibility,
  ) {
    return '$name, $rating puan. $route. Kişi başı $fare. $compatibility rota uyumu.';
  }

  @override
  String homeCompatibility(String value) {
    return '$value uyum';
  }

  @override
  String get searchTitle => 'Rota ara';

  @override
  String get searchFieldOriginLabel => 'NEREDEN';

  @override
  String get searchFieldDestinationLabel => 'NEREYE';

  @override
  String get searchSwapSemanticLabel => 'Kalkış ve varış noktalarını değiştir';

  @override
  String get searchWhenLabel => 'NE ZAMAN';

  @override
  String get searchWhenValue => 'Yarın · 08:30';

  @override
  String get searchSeatsLabel => 'KOLTUK';

  @override
  String searchSeatsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kişi',
      one: '1 kişi',
    );
    return '$_temp0';
  }

  @override
  String get searchFiltersTitle => 'GÜVEN FİLTRELERİ';

  @override
  String get searchFilterVerifiedOnly => 'Sadece doğrulanmış';

  @override
  String get searchFilterMinRating => '4.5+ puan';

  @override
  String get searchFilterFemaleDriver => 'Kadın sürücü';

  @override
  String get searchFilterNoSmoking => 'Sigara yok';

  @override
  String get searchFilterMutualConnection => 'Ortak bağlantı';

  @override
  String get searchRecentTitle => 'SON ARAMALAR';

  @override
  String searchSubmit(String count) {
    return 'Eşleşmeleri gör · $count sonuç';
  }

  @override
  String get searchPlacePickerOriginTitle => 'Nereden yola çıkıyorsun?';

  @override
  String get searchPlacePickerDestinationTitle => 'Nereye gidiyorsun?';

  @override
  String matchesTitle(String count) {
    return '$count eşleşme';
  }

  @override
  String matchesSubtitle(String route, String when) {
    return '$route · $when';
  }

  @override
  String get matchesWhenSummary => 'Yarın 08:30';

  @override
  String get matchesSortBest => 'En uyumlu';

  @override
  String get matchesSortNearest => 'En yakın';

  @override
  String get matchesSortCheapest => 'En ucuz';

  @override
  String get matchesCompatibilityLabel => 'Rota uyumu';

  @override
  String get matchesInspect => 'İncele';

  @override
  String get matchesMetaVerified => 'Doğrulanmış';

  @override
  String matchesMetaTrips(String count) {
    return '$count yolculuk';
  }

  @override
  String matchesMetaSharedRoutes(String count) {
    return '$count ortak rota';
  }

  @override
  String matchesMetaDeparture(String time) {
    return 'Kalkış $time';
  }

  @override
  String matchesMetaSeats(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count koltuk',
      one: '1 koltuk',
    );
    return '$_temp0';
  }

  @override
  String matchesMetaWalk(String minutes) {
    return '~$minutes dk yürüme';
  }

  @override
  String matchesMetaCompatibilityShort(String value) {
    return '$value uyum';
  }

  @override
  String matchesCardSemanticLabel(
    String name,
    String rating,
    String compatibility,
    String time,
    String fare,
  ) {
    return '$name, $rating puan. $compatibility rota uyumu. Kalkış $time. Kişi başı $fare.';
  }

  @override
  String get routeDetailsStatTrustScore => 'Güven Puanı';

  @override
  String get routeDetailsStatApprovalRate => 'Onay oranı';

  @override
  String get routeDetailsStatSharedDistance => 'km paylaşıldı';

  @override
  String routeDetailsMemberSince(String year, String area) {
    return '$year\'ten beri üye · $area';
  }

  @override
  String routeDetailsRatingSummary(String rating, String trips) {
    return '$rating · $trips yolculuk';
  }

  @override
  String get routeDetailsPickupLabel => 'Alış noktası';

  @override
  String routeDetailsArrivalLabel(String minutes) {
    return 'Varış · $minutes dk';
  }

  @override
  String get routeDetailsMutualTitle => 'Ortak bağlantı';

  @override
  String get routeDetailsFareLabel => 'Senin payın';

  @override
  String get routeDetailsMessageSemanticLabel => 'Sürücüye mesaj gönder';

  @override
  String get routeDetailsRequestSeat => 'İstek gönder';

  @override
  String get routeDetailsRequestUnavailable =>
      'Yolculuk isteği özelliği yakında eklenecek.';

  @override
  String get routeDetailsMessagingUnavailable =>
      'Mesajlaşma özelliği yakında eklenecek.';

  @override
  String get routeDetailsNotFound => 'Bu rota artık görüntülenemiyor.';

  @override
  String get dateToday => 'Bugün';

  @override
  String get dateYesterday => 'Dün';

  @override
  String get dateTomorrow => 'Yarın';

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün önce',
      one: '1 gün önce',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hafta önce',
      one: '1 hafta önce',
    );
    return '$_temp0';
  }
}
