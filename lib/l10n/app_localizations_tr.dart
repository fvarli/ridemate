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
  String get routeDetailsNotFound => 'Bu rota artık görüntülenemiyor.';

  @override
  String get createRouteTitle => 'Rota oluştur';

  @override
  String get createRouteSubtitle => 'Sürücü olarak koltuk paylaş';

  @override
  String createRouteOriginSemanticLabel(String place) {
    return 'Kalkış: $place';
  }

  @override
  String createRouteDestinationSemanticLabel(String place) {
    return 'Varış: $place';
  }

  @override
  String get createRouteOriginPickerTitle => 'Nereden yola çıkıyorsun?';

  @override
  String get createRouteDestinationPickerTitle => 'Nereye gidiyorsun?';

  @override
  String get createRouteRecurrenceTitle => 'Her hafta içi tekrarla';

  @override
  String createRouteRecurrenceDetail(String time) {
    return 'Pzt–Cum · $time kalkış';
  }

  @override
  String get createRouteSeatsLabel => 'BOŞ KOLTUK';

  @override
  String get createRouteSeatsSemanticLabel => 'Boş koltuk';

  @override
  String createRouteSeatsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count koltuk',
      one: '1 koltuk',
    );
    return '$_temp0';
  }

  @override
  String get createRouteCostShareLabel => 'KİŞİ BAŞI';

  @override
  String get createRouteCostShareCaption => 'Önerilen · maliyet paylaşımı';

  @override
  String createRouteCostShareSemanticLabel(String amount) {
    return 'Kişi başı önerilen maliyet paylaşımı: $amount';
  }

  @override
  String get createRouteRulesTitle => 'YOLCULUK KURALLARI';

  @override
  String get createRouteRuleNoSmoking => 'Sigara yok';

  @override
  String get createRouteRuleMusicOk => 'Müzik OK';

  @override
  String get createRouteRuleNoPets => 'Evcil hayvan yok';

  @override
  String get createRouteRuleQuiet => 'Sessiz';

  @override
  String get createRoutePublish => 'Rotayı yayınla';

  @override
  String get createRoutePublishUnavailable =>
      'Rota henüz yayınlanmadı. Yayınlama özelliği yakında eklenecek.';

  @override
  String get activeTripLiveBadge => 'CANLI YOLCULUK';

  @override
  String get activeTripEtaLabel => 'Levent\'e varış';

  @override
  String activeTripEtaValue(String duration, String distance) {
    return '$duration $distance';
  }

  @override
  String get activeTripOnTime => 'Zamanında';

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
    return '$name, $rating puan, çevrimiçi. $vehicle, $plate.';
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
  String get activeTripCall => 'Sürücüyü ara';

  @override
  String get activeTripMessage => 'Sürücüye mesaj gönder';

  @override
  String get activeTripShare => 'Yolculuğu paylaş';

  @override
  String get sosLabel => 'SOS';

  @override
  String activeTripLocationSharing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Canlı konumun $count acil kişiyle paylaşılıyor',
      one: 'Canlı konumun 1 acil kişiyle paylaşılıyor',
    );
    return '$_temp0';
  }

  @override
  String get activeTripShareUnavailable =>
      'Yolculuk paylaşma özelliği henüz aktif değil. Hiçbir şey paylaşılmadı.';

  @override
  String get activeTripCallUnavailable =>
      'Arama özelliği henüz aktif değil. Hiçbir arama başlatılmadı.';

  @override
  String get sosUnavailable =>
      'Acil durum özelliği henüz aktif değil. Kimseye bildirim gönderilmedi.';

  @override
  String get chatOnline => 'Çevrimiçi';

  @override
  String chatHeaderSemanticLabel(String name) {
    return '$name, kimliği doğrulanmış, çevrimiçi';
  }

  @override
  String get chatSafetyBanner =>
      'Ödeme özelliği henüz aktif değil. Kişisel veya finansal bilgilerinizi paylaşmayın.';

  @override
  String get chatMessageIncoming =>
      'Merhaba Elif! Yarın 08:25\'te Kadıköy İskele\'de olurum 👍';

  @override
  String get chatMessageOutgoing =>
      'Harika, teşekkürler! Ben de orada olacağım.';

  @override
  String get chatMessageOutgoingClosing => 'Görüşürüz 🙌';

  @override
  String get chatLocationLabel => '📍 Buluşma noktası';

  @override
  String chatLocationSemanticLabel(String name, String label) {
    return '$name konum paylaştı: $label';
  }

  @override
  String chatBubbleSemanticLabel(String speaker, String text) {
    return '$speaker: $text';
  }

  @override
  String get chatSpeakerSelf => 'Sen';

  @override
  String get chatQuickReplyOnMyWay => 'Yoldayım';

  @override
  String get chatQuickReplyRunningLate => '5 dk geç';

  @override
  String get chatComposerHint => 'Mesaj yaz…';

  @override
  String get chatComposerLabel => 'Mesajını yaz';

  @override
  String get chatSend => 'Gönder';

  @override
  String get chatSendUnavailable =>
      'Mesaj gönderilmedi. Mesajlaşma özelliği henüz eklenmedi.';

  @override
  String get profileMemberBadge => 'Doğrulanmış üye · 2024\'ten beri';

  @override
  String get profileTrustScoreTitle => 'Güven Puanı';

  @override
  String get profileTrustScoreOutOf => '/ 100';

  @override
  String profileTrustTier(String percentile) {
    return 'Üst $percentile · Güvenilir';
  }

  @override
  String get profileTrustNextStep => '100\'e ulaşmak için 1 yolculuk daha';

  @override
  String get profileTrustFactorIdentity => 'Kimlik';

  @override
  String get profileTrustFactorCommunity => 'Topluluk';

  @override
  String get profileTrustFactorReliability => 'Güvenilirlik';

  @override
  String get profileTrustFactorActivity => 'Aktiflik';

  @override
  String get profileStatTrips => 'Yolculuk';

  @override
  String get profileStatRating => 'Puan';

  @override
  String get profileStatSavings => 'Tasarruf';

  @override
  String get profileVerificationBadges => 'Doğrulama rozetleri';

  @override
  String get profileMyReviews => 'Değerlendirmelerim';

  @override
  String profileTrustScoreSemanticLabel(String score) {
    return 'Güven Puanı: $score, 100 üzerinden';
  }

  @override
  String profileTrustFactorSemanticLabel(String label, String value) {
    return '$label: $value';
  }

  @override
  String profileTrustFactorAttentionSemanticLabel(String label, String value) {
    return '$label: $value, dikkat';
  }

  @override
  String profileVerificationBadgesSemanticLabel(String done, String total) {
    return 'Doğrulama rozetleri: $total adımdan $done tanesi tamamlandı';
  }

  @override
  String get reviewsTitle => 'Değerlendirmeler';

  @override
  String reviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count değerlendirme',
    );
    return '$_temp0';
  }

  @override
  String get reviewsTagPunctual => 'Dakik';

  @override
  String get reviewsTagSafeDriving => 'Güvenli sürüş';

  @override
  String get reviewsTagFriendly => 'Güler yüzlü';

  @override
  String get reviewsTagCleanCar => 'Temiz araç';

  @override
  String reviewsTagLabel(String label, String count) {
    return '$label · $count';
  }

  @override
  String get reviewsContextRegularRoute => 'Düzenli rota';

  @override
  String get reviewsMockBodyFirst =>
      'Çok güvenli ve dakik bir yolculuktu. Selin gerçekten güler yüzlü, kesinlikle tekrar tercih ederim.';

  @override
  String get reviewsMockBodySecond =>
      'Her sabah aynı saatte, tertemiz araç. Trafikte sohbet etmek güzel.';

  @override
  String reviewsRatingSemanticLabel(String rating) {
    return '5 üzerinden $rating';
  }

  @override
  String reviewsDistributionSemanticLabel(String stars, String share) {
    return '$stars yıldız: değerlendirmelerin $share kadarı';
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
  String get safetyTitle => 'Güvenlik Merkezi';

  @override
  String get safetySubtitle => 'Her yolculukta yanındayız';

  @override
  String get safetySosTitle => 'Acil yardım';

  @override
  String get safetySosPromise =>
      'Bas, konumun ve yolculuk bilgin acil kişilere + ekibimize gider.';

  @override
  String get safetyCallEmergencyTitle => '112\'yi ara';

  @override
  String get safetyCallEmergencyCaption => 'Acil servis';

  @override
  String get safetyShareTripTitle => 'Yolculuğu paylaş';

  @override
  String get safetyShareTripCaption => 'Canlı konum';

  @override
  String safetyQuickActionSemanticLabel(String title, String caption) {
    return '$title. $caption';
  }

  @override
  String get safetyTrustedContactsTitle => 'Güvenilir kişiler';

  @override
  String safetyTrustedContactsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kişi eklendi',
      one: '1 kişi eklendi',
    );
    return '$_temp0';
  }

  @override
  String get safetyVerifyPartnerTitle => 'Yol arkadaşını doğrula';

  @override
  String get safetyVerifyPartnerSubtitle => 'QR ile kimlik eşleştir';

  @override
  String get safetyBlockReportTitle => 'Kullanıcı engelle / bildir';

  @override
  String get safetyBlockReportSubtitle => 'Gizli inceleme';

  @override
  String get safetyCallUnavailable => 'Uygulama henüz arama başlatamıyor.';

  @override
  String get safetyTrustedContactsUnavailable =>
      'Güvenilir kişiler özelliği henüz eklenmedi.';

  @override
  String get safetyVerifyPartnerUnavailable =>
      'QR ile doğrulama özelliği henüz eklenmedi.';

  @override
  String get safetyBlockReportUnavailable =>
      'Kullanıcı engelleme özelliği henüz eklenmedi.';

  @override
  String get errorTitle => 'Bir şeyler ters gitti';

  @override
  String get errorBody =>
      'Bu sayfa açılamadı. Ana sayfaya dönüp tekrar deneyebilirsin.';

  @override
  String get errorReturnHome => 'Ana sayfaya dön';

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
