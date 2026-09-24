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
  String get commonRetry => 'Yeniden dene';

  @override
  String get commonBack => 'Geri';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonLoading => 'Yükleniyor';

  @override
  String get commonRefreshFailed =>
      'Yenilenemedi. Gösterilenler güncel olmayabilir.';

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
      'Komşular, iş arkadaşları ve öğrencilerle. Taksi değil — topluluk.';

  @override
  String get onboardingCreateAccount => 'Hesap oluştur';

  @override
  String get onboardingSignIn => 'Zaten üyeyim';

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
  String homeGreetingNamed(String name) {
    return 'Merhaba, $name';
  }

  @override
  String get homeFindRide => 'Yolculuk bul';

  @override
  String get homeFindRideSemanticLabel => 'Yolculuk bul. Aramayı açar.';

  @override
  String get homeDrivingTitle => 'Sürdüğün yolculuklar';

  @override
  String get homeRequestsTitle => 'Koltuk isteklerin';

  @override
  String get homeSeeAll => 'Tümü';

  @override
  String get homeManageTitle => 'Yönet';

  @override
  String homeRequestSemanticLabel(String route, String date, String status) {
    return '$route, $date, $status';
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
  String matchesMetaSharedRoutes(String count) {
    return '$count ortak rota';
  }

  @override
  String get discoveryTitle => 'Yolculuklar';

  @override
  String get searchSubmit => 'Yolculukları ara';

  @override
  String get searchIncomplete => 'İki farklı yer seç.';

  @override
  String get discoveryIdle => 'Nereden nereye gittiğini seç.';

  @override
  String get discoveryEmpty => 'Bu iki yer arasında yayınlanmış yolculuk yok.';

  @override
  String get discoveryEmptyBody =>
      'Daha sonra tekrar bak ya da başka bir güzergah dene.';

  @override
  String get discoveryOrdering => 'En son yayınlananlar önce';

  @override
  String discoverySeatsOffered(int count) {
    return '$count koltuk sunuluyor';
  }

  @override
  String get discoveryLoadMore => 'Daha fazla göster';

  @override
  String get discoveryLoadMoreFailed => 'Daha fazlası alınamadı.';

  @override
  String get seatRequestAsk => 'Koltuk iste';

  @override
  String get seatRequestSending => 'Gönderiliyor…';

  @override
  String get seatRequestPending => 'İstek gönderildi';

  @override
  String get seatRequestAccepted => 'Kabul edildi';

  @override
  String get seatRequestDeclined => 'Reddedildi';

  @override
  String get seatRequestWithdrawn => 'Geri çekildi';

  @override
  String get seatRequestFailed => 'İstek gönderilemedi';

  @override
  String get seatRequestOwnRoute => 'Bu senin yolculuğun';

  @override
  String get seatRequestRouteFull => 'Sunulan koltukların tamamı verilmiş';

  @override
  String get seatRequestUnavailable => 'Bu yolculuk artık geçerli değil';

  @override
  String get seatRequestChooseDayTitle => 'Hangi gün?';

  @override
  String get seatRequestChooseDayBody =>
      'Bu plan birden çok gün çalışıyor. Koltuk istediğin günü seç.';

  @override
  String get seatRequestChooseDay => 'Gün seç';

  @override
  String get seatRequestNoDaysOffered => 'Şu anda istenebilecek bir gün yok';

  @override
  String get seatRequestEveryDayAsked =>
      'Sunulan günlerin hepsi için istek gönderdin';

  @override
  String get myRequestsTitle => 'İsteklerim';

  @override
  String get myRequestsSubtitle => 'En son gönderilenler önce';

  @override
  String get myRequestsEmpty => 'Henüz koltuk istemedin';

  @override
  String get myRequestsEmptyBody =>
      'Bir yolculuk bulup koltuk istediğinde burada görünür.';

  @override
  String get myRequestsLoadMore => 'Daha fazla göster';

  @override
  String get myRequestsLoadMoreFailed => 'Sonraki istekler yüklenemedi';

  @override
  String get myRequestsWithdraw => 'İsteği geri çek';

  @override
  String get myRequestsWithdrawn => 'İstek geri çekildi';

  @override
  String get myRequestsWithdrawFailed => 'İstek geri çekilemedi';

  @override
  String get myRequestsRouteCancelled => 'Bu yolculuk iptal edildi';

  @override
  String get myRequestsRouteDeparted => 'Bu yolculuk geçti';

  @override
  String get myRequestsOpen => 'İsteklerim';

  @override
  String get routeRequestsOpen => 'İstekler';

  @override
  String routeRequestsOpenSemanticLabel(String journey) {
    return '$journey için gelen istekler';
  }

  @override
  String get routeRequestsTitle => 'Gelen istekler';

  @override
  String get routeRequestsEmpty => 'Bu yolculuk için henüz istek yok';

  @override
  String get routeRequestsEmptyBody =>
      'Biri koltuk istediğinde burada görünür.';

  @override
  String get routeRequestsLoadMore => 'Daha fazla göster';

  @override
  String get routeRequestsLoadMoreFailed => 'Sonraki istekler yüklenemedi';

  @override
  String get routeRequestsAccept => 'Kabul et';

  @override
  String get routeRequestsDecline => 'Reddet';

  @override
  String routeRequestsAcceptSemanticLabel(String passenger) {
    return '$passenger isteğini kabul et';
  }

  @override
  String routeRequestsDeclineSemanticLabel(String passenger) {
    return '$passenger isteğini reddet';
  }

  @override
  String get routeRequestsAccepted => 'İstek kabul edildi';

  @override
  String get routeRequestsDeclined => 'İstek reddedildi';

  @override
  String get routeRequestsFull => 'Sunulan koltukların tamamı verilmiş';

  @override
  String get routeRequestsRouteUnavailable => 'Bu yolculuk artık geçerli değil';

  @override
  String get routeRequestsDecisionFailed => 'İstek yanıtlanamadı';

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
  String get searchPlacePickerOriginTitle => 'Nereden yola çıkıyorsun?';

  @override
  String get searchPlacePickerDestinationTitle => 'Nereye gidiyorsun?';

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
  String get routeDetailsCostShareLabel => 'Senin payın';

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
  String get createRouteOriginEmpty => 'Kalkış noktası seç';

  @override
  String get createRouteDestinationEmpty => 'Varış noktası seç';

  @override
  String get createRouteEndpointsSame => 'Kalkış ve varış aynı yer olamaz.';

  @override
  String get createRoutePlacesLoading => 'Yerler yükleniyor…';

  @override
  String get createRoutePlacesEmpty => 'Şu anda desteklenen bir yer yok.';

  @override
  String get createRoutePlacesUnavailable => 'Yer listesi alınamadı.';

  @override
  String get createRouteRecurrenceTitle => 'Her hafta içi tekrarla';

  @override
  String get createRouteRecurrenceDetail => 'Pzt–Cum';

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
  String get createRouteDepartureDateLabel => 'GİDİŞ TARİHİ';

  @override
  String get createRouteDepartureDateEmpty => 'Tarih seç';

  @override
  String get createRouteDepartureTimeLabel => 'GİDİŞ SAATİ';

  @override
  String get createRouteDepartureTimeEmpty => 'Saat seç';

  @override
  String get createRouteDepartureDateMissing => 'Gidiş tarihi seç.';

  @override
  String get createRouteDepartureTimeMissing => 'Gidiş saati seç.';

  @override
  String get createRoutePublished => 'Rotan yayınlandı.';

  @override
  String get createRoutePublishFailed => 'Rota yayınlanamadı.';

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
  String get profileMyReviews => 'Hakkımdaki değerlendirmeler';

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
  String get messagesPlaceholderBody => 'Sohbet listesi henüz eklenmedi.';

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

  @override
  String get errorNetwork =>
      'Bağlantı kurulamadı. İnternet bağlantını kontrol et.';

  @override
  String get errorConflict =>
      'Bu işlem mevcut durum nedeniyle tamamlanamadı. Bilgileri yenileyip tekrar deneyin.';

  @override
  String get errorUnexpected =>
      'Beklenmeyen bir sorun oluştu. Lütfen tekrar dene.';

  @override
  String get errorValidation => 'Girdiğin bilgileri kontrol et.';

  @override
  String get errorUnauthenticated => 'Oturumun sona erdi. Tekrar giriş yap.';

  @override
  String get errorForbidden => 'Hesabın askıya alındı.';

  @override
  String get errorRateLimited =>
      'Çok fazla deneme yapıldı. Biraz sonra tekrar dene.';

  @override
  String get profileSetupTitle => 'Sana nasıl hitap edelim?';

  @override
  String get profileSetupBody =>
      'Bu ad, yolculuk paylaştığın kişilere görünür.';

  @override
  String get profileSetupFieldLabel => 'Adın';

  @override
  String get profileSetupFieldHint => 'Ayşe Demir';

  @override
  String get profileSetupSubmit => 'Devam et';

  @override
  String get authPhoneTitle => 'Telefon numaran';

  @override
  String get authPhoneBody =>
      'Sana altı haneli bir doğrulama kodu göndereceğiz.';

  @override
  String get authPhoneFieldLabel => 'Telefon numarası';

  @override
  String get authPhoneFieldHint => '0532 123 45 67';

  @override
  String get authPhoneInvalid => 'Geçerli bir telefon numarası gir.';

  @override
  String get authPhoneSubmit => 'Kod gönder';

  @override
  String get authCodeTitle => 'Doğrulama kodu';

  @override
  String authCodeBody(String phone) {
    return '$phone numarasına gönderilen kodu gir.';
  }

  @override
  String get authCodeFieldLabel => 'Altı haneli kod';

  @override
  String get authCodeInvalid => 'Kod doğru değil. Tekrar dene.';

  @override
  String get authCodeSubmit => 'Doğrula';

  @override
  String get authCodeResend => 'Kodu tekrar gönder';

  @override
  String get authCodeResent => 'Yeni bir kod gönderildi.';

  @override
  String get myRoutesTitle => 'Rotalarım';

  @override
  String get profileEditName => 'Adını düzenle';

  @override
  String get profileEditSave => 'Kaydet';

  @override
  String get profileNoProfileYet => 'Henüz bir adın yok.';

  @override
  String get profileMyRoutes => 'Rotalarım';

  @override
  String myRoutesSeatsOffered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count koltuk sunuluyor',
      one: '1 koltuk sunuluyor',
    );
    return '$_temp0';
  }

  @override
  String get myRoutesRecurrenceWeekdays => 'Her hafta içi';

  @override
  String get myRoutesStatusPublished => 'Yayında';

  @override
  String get myRoutesStatusCancelled => 'İptal edildi';

  @override
  String get myRoutesStatusPast => 'Geçmiş';

  @override
  String get myRoutesEmptyTitle => 'Henüz rota yayınlamadın';

  @override
  String get myRoutesEmptyBody => 'Yayınladığın rotalar burada görünür.';

  @override
  String get myRoutesLoadMore => 'Daha fazla yükle';

  @override
  String get myRoutesLoadMoreFailed => 'Sonraki sayfa yüklenemedi.';

  @override
  String get myRoutesCancel => 'Rotayı iptal et';

  @override
  String get myRoutesCancelConfirmTitle => 'Bu rota iptal edilsin mi?';

  @override
  String myRoutesCancelConfirmBody(String route) {
    return '$route rotası yayından kalkar. Geçmişinde kalmaya devam eder.';
  }

  @override
  String get myRoutesCancelConfirm => 'Evet, iptal et';

  @override
  String get myRoutesCancelDismiss => 'Vazgeç';

  @override
  String get myRoutesCancelled => 'Rota iptal edildi.';

  @override
  String get tripStateNotStarted => 'Başlamadı';

  @override
  String get tripStateInProgress => 'Başladı';

  @override
  String get tripStateCompleted => 'Tamamlandı';

  @override
  String get tripStateAborted => 'Yarıda bırakıldı';

  @override
  String tripStateLine(String state) {
    return 'Yolculuk: $state';
  }

  @override
  String get myRoutesStartTrip => 'Yolculuğu başlat';

  @override
  String myRoutesStartTripSemanticLabel(String route) {
    return '$route yolculuğunu başlat';
  }

  @override
  String myRoutesTripStarted(String route) {
    return '$route yolculuğu başladı.';
  }

  @override
  String get myRoutesCompleteTrip => 'Yolculuğu tamamla';

  @override
  String myRoutesCompleteTripSemanticLabel(String route) {
    return '$route yolculuğunu tamamla';
  }

  @override
  String get myRoutesAbortTrip => 'Yolculuğu yarıda bırak';

  @override
  String myRoutesAbortTripSemanticLabel(String route) {
    return '$route yolculuğunu yarıda bırak';
  }

  @override
  String myRoutesTripCompleted(String route) {
    return '$route yolculuğu tamamlandı.';
  }

  @override
  String myRoutesTripAborted(String route) {
    return '$route yolculuğu yarıda bırakıldı.';
  }

  @override
  String get myRoutesTripNotStarted => 'Bu yolculuk henüz başlatılmamış.';

  @override
  String get myRoutesStartDepartureNotReached =>
      'Bu yolculuk henüz başlatılamaz.';

  @override
  String get myRoutesStartRecurringUnsupported =>
      'Hangi günü kastettiğini seç ve yolculuğu oradan başlat.';

  @override
  String get myRoutesStartServiceDatePassed =>
      'O günün yolculuğu artık başlatılamaz.';

  @override
  String get myRoutesStartRouteUnavailable => 'Bu rota artık başlatılamaz.';

  @override
  String get myRoutesTripAlreadyCompleted => 'Bu yolculuk zaten tamamlanmış.';

  @override
  String get myRoutesTripAlreadyAborted =>
      'Bu yolculuk zaten yarıda bırakılmış.';

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
    return '$route rotasını iptal et';
  }

  @override
  String get reviewSubmit => 'Yolculuğu değerlendir';

  @override
  String reviewSubmitSemanticLabel(String member) {
    return '$member ile yaptığın yolculuğu değerlendir';
  }

  @override
  String get reviewSheetTitle => 'Bu yolculuğu değerlendir';

  @override
  String get reviewSheetBody =>
      'Değerlendirmen yalnızca değerlendirdiğin kişiye gösterilir; o da seni değerlendirdiğinde ya da süre dolduğunda. Puan ortalaması, sayısı veya herkese açık bir profil yok.';

  @override
  String reviewStarSemanticLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yıldız',
      one: '1 yıldız',
    );
    return '$_temp0';
  }

  @override
  String get reviewSend => 'Gönder';

  @override
  String get reviewDismiss => 'Vazgeç';

  @override
  String reviewSubmitted(int rating) {
    return 'Değerlendirmen: $rating/5';
  }

  @override
  String get reviewSubmittedToast => 'Değerlendirmen kaydedildi.';

  @override
  String get reviewRetry => 'Aynı değerlendirmeyi tekrar gönder';

  @override
  String get reviewAbandon => 'Bu denemeden vazgeç';

  @override
  String get reviewIndeterminate =>
      'Değerlendirmen gönderilemedi. Aynı puanla tekrar deneyebilirsin.';

  @override
  String get reviewWindowClosed => 'Bu yolculuğun değerlendirme süresi doldu.';

  @override
  String get reviewAlreadyReviewed => 'Bu yolculuğu zaten değerlendirmişsin.';

  @override
  String get reviewNotEligible => 'Bu yolculuk artık değerlendirilemiyor.';

  @override
  String get reviewIdConflict =>
      'Bu değerlendirme gönderilemedi. Listeyi yenileyip tekrar dene.';

  @override
  String get tripStatusTitle => 'Yolculuk durumu';

  @override
  String get tripStatusDeparture => 'Planlanan kalkış';

  @override
  String get tripStatusState => 'Durum';

  @override
  String get tripStatusStartedNote =>
      'Bu yalnızca yolculuğu RideMate\'te başlattığını gösterir. Konum, harita, navigasyon veya yolcu bilgisi tutulmaz.';

  @override
  String get tripStatusStartedAt => 'Başlangıç';

  @override
  String get tripStatusCompletedAt => 'Tamamlanma';

  @override
  String get tripStatusAbortedAt => 'Yarıda bırakılma';

  @override
  String get tripStatusServiceDate => 'Yolculuk günü';

  @override
  String get tripStatusNotFound => 'Bu rota listende yok';

  @override
  String get tripStatusNotFoundBody =>
      'Rotalarını yeniden yükleyip tekrar dene.';

  @override
  String get journeysSectionTitle => 'Yolculuklar';

  @override
  String get journeysSectionBody =>
      'Bugün çalışan yolculuklar ve başlattığın yolculuklar.';

  @override
  String get journeysEmpty => 'Bugün çalışan bir yolculuk yok';

  @override
  String get journeysEmptyBody =>
      'Rotalarından biri çalıştığı her gün burada bir yolculuk görünür.';

  @override
  String get journeysFailed => 'Yolculukların yüklenemedi.';

  @override
  String get journeyNotFound => 'Bu yolculuk okunamadı';

  @override
  String get journeyNotFoundBody => 'Günü kontrol edip tekrar dene.';

  @override
  String journeyCardSemanticLabel(
    String route,
    String date,
    String departure,
    String trip,
  ) {
    return '$route, $date, $departure, $trip';
  }

  @override
  String journeyOpenSemanticLabel(String route, String date) {
    return '$route rotasının $date günündeki yolculuğunu aç';
  }

  @override
  String get receivedReviewsTitle => 'Hakkındaki değerlendirmeler';

  @override
  String get receivedReviewsSubtitle => 'En son gönderilenler önce';

  @override
  String get receivedReviewsEmpty => 'Görüntülenebilecek bir geri bildirim yok';

  @override
  String get receivedReviewsEmptyBody =>
      'Yeni geri bildirimler burada görünür.';

  @override
  String get receivedReviewsLoadMore => 'Daha fazla göster';

  @override
  String get receivedReviewsLoadMoreFailed =>
      'Sonraki geri bildirimler yüklenemedi';

  @override
  String get receivedReviewsRoleDriver => 'Sürücü';

  @override
  String get receivedReviewsRolePassenger => 'Yolcu';

  @override
  String receivedReviewRatingSemanticLabel(int rating) {
    return '5 üzerinden $rating';
  }

  @override
  String receivedReviewSubmittedAt(String when) {
    return 'Gönderildi: $when';
  }

  @override
  String receivedReviewCardSemanticLabel(
    String member,
    String role,
    String rating,
    String journey,
    String departure,
  ) {
    return '$member, $role. $rating. $journey, $departure';
  }
}
