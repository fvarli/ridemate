import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// Ürün adı. Çevrilmez.
  ///
  /// In tr, this message translates to:
  /// **'RideMate'**
  String get appTitle;

  /// Alt gezinme çubuğu: ana sekme.
  ///
  /// In tr, this message translates to:
  /// **'Anasayfa'**
  String get navHome;

  /// Alt gezinme çubuğu: rota arama sekmesi.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get navSearch;

  /// Alt gezinme çubuğu: mesajlar sekmesi.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlar'**
  String get navMessages;

  /// Alt gezinme çubuğu: profil sekmesi.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// Alt gezinme çubuğunun ortasındaki eylem düğmesi. Sürücü olarak rota yayınlama akışını açar.
  ///
  /// In tr, this message translates to:
  /// **'Rota oluştur'**
  String get navCreateRoute;

  /// Geri düğmesi için erişilebilirlik etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get commonBack;

  /// Kapatma düğmesi için erişilebilirlik etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get commonClose;

  /// Bir işlem sürerken ekran okuyucuya bildirilen durum.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor'**
  String get commonLoading;

  /// Kilometre cinsinden mesafe. Sayı yerel biçimde gelir (örn. 6,2).
  ///
  /// In tr, this message translates to:
  /// **'{value} km'**
  String unitDistanceKm(String value);

  /// Dakika cinsinden süre kısaltması.
  ///
  /// In tr, this message translates to:
  /// **'{value} dk'**
  String unitDurationMinutes(String value);

  /// Yaklaşık süre. Tasarımda '~5 dk yürüme' gibi kullanılır.
  ///
  /// In tr, this message translates to:
  /// **'~{value} dk'**
  String unitDurationApproxMinutes(String value);

  /// Onboarding başlığının vurgulanan kelimeden önceki bölümü. Başlık üç parçadan oluşur: bu metin, vurgulanan kelime, sonra kalan metin.
  ///
  /// In tr, this message translates to:
  /// **'Aynı yöne gidenlerle '**
  String get onboardingHeadlineBefore;

  /// Onboarding başlığında marka rengiyle vurgulanan tek kelime.
  ///
  /// In tr, this message translates to:
  /// **'güvenle'**
  String get onboardingHeadlineEmphasis;

  /// Onboarding başlığının vurgulanan kelimeden sonraki bölümü.
  ///
  /// In tr, this message translates to:
  /// **' yola çık'**
  String get onboardingHeadlineAfter;

  /// Onboarding alt başlığı. RideMate'in taksi olmadığını vurgular.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanmış komşular, iş arkadaşları ve öğrencilerle. Taksi değil — topluluk.'**
  String get onboardingSubtitle;

  /// Topluluk kanıtı satırı. Sayı yerel biçimde ve mono yazı tipiyle gösterilir; bu metin mock sunum verisidir.
  ///
  /// In tr, this message translates to:
  /// **'{count} doğrulanmış üye İstanbul\'da'**
  String onboardingSocialProof(String count);

  /// Birincil eylem. Yeni kullanıcı akışına devam eder. Bu bir hesap oluşturma veya kimlik doğrulama işlemi DEĞİLDİR; uygulamada henüz hesap kavramı yoktur.
  ///
  /// In tr, this message translates to:
  /// **'Hesap oluştur'**
  String get onboardingCreateAccount;

  /// İkincil eylem. Mevcut hesapla giriş yapmayı ifade eder. Giriş özelliği henüz yoktur.
  ///
  /// In tr, this message translates to:
  /// **'Zaten üyeyim'**
  String get onboardingSignIn;

  /// "Zaten üyeyim" dokunulduğunda gösterilen geçici bilgi mesajı. Kimlik doğrulama uygulanana kadar geçerlidir.
  ///
  /// In tr, this message translates to:
  /// **'Giriş özelliği yakında eklenecek.'**
  String get onboardingSignInUnavailable;

  /// Kimlik doğrulama ekranının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Kimlik doğrulama'**
  String get verificationTitle;

  /// Güven Puanı halkasının içindeki küçük etiket.
  ///
  /// In tr, this message translates to:
  /// **'PUAN'**
  String get verificationScoreCaption;

  /// Güven Puanı kartının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Güven Puanın oluşuyor'**
  String get verificationHeroTitle;

  /// Kart açıklamasının vurgulanan kelimeden önceki bölümü.
  ///
  /// In tr, this message translates to:
  /// **'{count} adım daha tamamla, '**
  String verificationHeroSubtitleBefore(String count);

  /// Kart açıklamasında vurgulanan rozet adı.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanmış'**
  String get verificationHeroSubtitleEmphasis;

  /// Kart açıklamasının vurgulanan kelimeden sonraki bölümü.
  ///
  /// In tr, this message translates to:
  /// **' rozetini kazan.'**
  String get verificationHeroSubtitleAfter;

  /// Gerekli tüm adımlar doğrulandığında kartta gösterilen açıklama.
  ///
  /// In tr, this message translates to:
  /// **'Tüm gerekli adımlar tamamlandı.'**
  String get verificationHeroComplete;

  /// Doğrulama adımı: telefon.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numarası'**
  String get verificationStepPhone;

  /// Doğrulama adımı: e-posta.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi'**
  String get verificationStepEmail;

  /// Doğrulama adımı: kimlik belgesi.
  ///
  /// In tr, this message translates to:
  /// **'Kimlik (T.C. / Pasaport)'**
  String get verificationStepIdentity;

  /// Doğrulama adımı: selfie eşleştirme.
  ///
  /// In tr, this message translates to:
  /// **'Selfie eşleştirme'**
  String get verificationStepSelfie;

  /// Doğrulama adımı: ehliyet. Yalnızca sürücüler için gereklidir.
  ///
  /// In tr, this message translates to:
  /// **'Ehliyet'**
  String get verificationStepLicence;

  /// Ehliyet adımının başlığına eklenen, vurgusu azaltılmış açıklama.
  ///
  /// In tr, this message translates to:
  /// **' · sürücüysen'**
  String get verificationStepLicenceQualifier;

  /// Doğrulanmış adımın alt satırı; detay maskelenmiş telefon gibi mock sunum verisidir.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulandı · {detail}'**
  String verificationStatusVerifiedWithDetail(String detail);

  /// Doğrulanmış adımın durumu.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulandı'**
  String get verificationStatusVerified;

  /// İşlemdeki adımın durumu. Süre mock sunum verisidir.
  ///
  /// In tr, this message translates to:
  /// **'İşleniyor · ~{minutes} dk'**
  String verificationStatusInProgress(String minutes);

  /// Henüz başlamamış zorunlu adımın durumu.
  ///
  /// In tr, this message translates to:
  /// **'Bekliyor'**
  String get verificationStatusPending;

  /// Zorunlu olmayan adımın durumu.
  ///
  /// In tr, this message translates to:
  /// **'Opsiyonel'**
  String get verificationStatusOptional;

  /// İşlemdeki adımın eylemi. Phase 2'de gerçek belge yükleme yoktur; yalnızca demo durumunu ilerletir.
  ///
  /// In tr, this message translates to:
  /// **'Yükle'**
  String get verificationUpload;

  /// Ana ekrandaki karşılama. Tasarımda yalnızca sabah karşılaması onaylanmıştır; günün saatine göre değişen varyantlar için ayrıca onaylı metin gerekir.
  ///
  /// In tr, this message translates to:
  /// **'Günaydın,'**
  String get homeGreeting;

  /// Arama alanının metni. Bu alan gerçek bir metin girişi değildir; dokunulduğunda arama ekranını açar.
  ///
  /// In tr, this message translates to:
  /// **'Nereye gidiyorsun?'**
  String get homeSearchPlaceholder;

  /// Arama alanının sonundaki eylem etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get homeSearchAction;

  /// Arama alanı için ekran okuyucu etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Nereye gidiyorsun? Rota ara.'**
  String get homeSearchSemanticLabel;

  /// Kayıtlı adres kısayolu: ev.
  ///
  /// In tr, this message translates to:
  /// **'Ev'**
  String get homeShortcutHome;

  /// Kayıtlı adres kısayolu: iş. Konum adı mock sunum verisidir.
  ///
  /// In tr, this message translates to:
  /// **'İş · Levent'**
  String get homeShortcutWork;

  /// Kayıtlı adres kısayolu: üniversite.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite'**
  String get homeShortcutUniversity;

  /// Yakındaki eşleşmeler kartının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Yakınındaki rotalar'**
  String get homeNearbyRoutesTitle;

  /// Tüm eşleşmeleri açan bağlantı. Sayı mock sunum verisidir.
  ///
  /// In tr, this message translates to:
  /// **'{count} eşleşme →'**
  String homeMatchCount(String count);

  /// Eşleşme kartı için ekran okuyucu etiketi.
  ///
  /// In tr, this message translates to:
  /// **'{name}, {rating} puan. {route}. Kişi başı {fare}. {compatibility} rota uyumu.'**
  String homeMatchSemanticLabel(
    String name,
    String rating,
    String route,
    String fare,
    String compatibility,
  );

  /// Rota uyumu rozeti. Değer mock sunum verisidir.
  ///
  /// In tr, this message translates to:
  /// **'{value} uyum'**
  String homeCompatibility(String value);

  /// Rota arama ekranının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Rota ara'**
  String get searchTitle;

  /// Kalkış alanının üst etiketi.
  ///
  /// In tr, this message translates to:
  /// **'NEREDEN'**
  String get searchFieldOriginLabel;

  /// Varış alanının üst etiketi.
  ///
  /// In tr, this message translates to:
  /// **'NEREYE'**
  String get searchFieldDestinationLabel;

  /// Yön değiştirme düğmesi için ekran okuyucu etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Kalkış ve varış noktalarını değiştir'**
  String get searchSwapSemanticLabel;

  /// Tarih/saat seçicisinin üst etiketi.
  ///
  /// In tr, this message translates to:
  /// **'NE ZAMAN'**
  String get searchWhenLabel;

  /// Seçili yolculuk zamanı. Mock sunum verisidir; Phase 3'te tarih seçici yoktur.
  ///
  /// In tr, this message translates to:
  /// **'Yarın · 08:30'**
  String get searchWhenValue;

  /// Koltuk seçicisinin üst etiketi.
  ///
  /// In tr, this message translates to:
  /// **'KOLTUK'**
  String get searchSeatsLabel;

  /// Seçili koltuk sayısı.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{1 kişi} other{{count} kişi}}'**
  String searchSeatsValue(int count);

  /// Güven filtreleri bölüm başlığı.
  ///
  /// In tr, this message translates to:
  /// **'GÜVEN FİLTRELERİ'**
  String get searchFiltersTitle;

  /// Filtre: yalnızca kimliği doğrulanmış üyeler.
  ///
  /// In tr, this message translates to:
  /// **'Sadece doğrulanmış'**
  String get searchFilterVerifiedOnly;

  /// Filtre: belirli puanın üzerindeki üyeler.
  ///
  /// In tr, this message translates to:
  /// **'4.5+ puan'**
  String get searchFilterMinRating;

  /// Filtre: kadın sürücü tercihi. Phase 3'te yalnızca sunum tercihidir; sonuçları etkilemez. Gerçek eşleştirmeye bağlanmadan önce hukuk, güvenlik ve ürün onayı gerekir.
  ///
  /// In tr, this message translates to:
  /// **'Kadın sürücü'**
  String get searchFilterFemaleDriver;

  /// Filtre: sigara içilmeyen yolculuk.
  ///
  /// In tr, this message translates to:
  /// **'Sigara yok'**
  String get searchFilterNoSmoking;

  /// Filtre: ortak bağlantısı olan üyeler.
  ///
  /// In tr, this message translates to:
  /// **'Ortak bağlantı'**
  String get searchFilterMutualConnection;

  /// Son aramalar bölüm başlığı.
  ///
  /// In tr, this message translates to:
  /// **'SON ARAMALAR'**
  String get searchRecentTitle;

  /// Eşleşmeleri açan ana eylem. Sayı mock sunum verisidir.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşmeleri gör · {count} sonuç'**
  String searchSubmit(String count);

  /// Kalkış noktası seçim sayfasının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Nereden yola çıkıyorsun?'**
  String get searchPlacePickerOriginTitle;

  /// Varış noktası seçim sayfasının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Nereye gidiyorsun?'**
  String get searchPlacePickerDestinationTitle;

  /// Eşleşme sonuçları başlığı.
  ///
  /// In tr, this message translates to:
  /// **'{count} eşleşme'**
  String matchesTitle(String count);

  /// Sonuç başlığının altındaki yolculuk özeti.
  ///
  /// In tr, this message translates to:
  /// **'{route} · {when}'**
  String matchesSubtitle(String route, String when);

  /// Sonuç başlığındaki kısa zaman özeti. Mock sunum verisidir.
  ///
  /// In tr, this message translates to:
  /// **'Yarın 08:30'**
  String get matchesWhenSummary;

  /// Sıralama seçeneği: rota uyumuna göre.
  ///
  /// In tr, this message translates to:
  /// **'En uyumlu'**
  String get matchesSortBest;

  /// Sıralama seçeneği: mesafeye göre.
  ///
  /// In tr, this message translates to:
  /// **'En yakın'**
  String get matchesSortNearest;

  /// Sıralama seçeneği: maliyet payına göre.
  ///
  /// In tr, this message translates to:
  /// **'En ucuz'**
  String get matchesSortCheapest;

  /// Uyum ölçeğinin etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Rota uyumu'**
  String get matchesCompatibilityLabel;

  /// Rota ayrıntılarını açan eylem.
  ///
  /// In tr, this message translates to:
  /// **'İncele'**
  String get matchesInspect;

  /// Kart üzerindeki doğrulanmış üye ifadesi.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanmış'**
  String get matchesMetaVerified;

  /// Tamamlanan yolculuk sayısı. Mock sunum verisidir.
  ///
  /// In tr, this message translates to:
  /// **'{count} yolculuk'**
  String matchesMetaTrips(String count);

  /// Ortak rota sayısı. Mock sunum verisidir.
  ///
  /// In tr, this message translates to:
  /// **'{count} ortak rota'**
  String matchesMetaSharedRoutes(String count);

  /// Kalkış saati.
  ///
  /// In tr, this message translates to:
  /// **'Kalkış {time}'**
  String matchesMetaDeparture(String time);

  /// Boş koltuk sayısı.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{1 koltuk} other{{count} koltuk}}'**
  String matchesMetaSeats(int count);

  /// Alış noktasına yürüme süresi.
  ///
  /// In tr, this message translates to:
  /// **'~{minutes} dk yürüme'**
  String matchesMetaWalk(String minutes);

  /// Sıkıştırılmış kartta gösterilen kısa uyum ifadesi.
  ///
  /// In tr, this message translates to:
  /// **'{value} uyum'**
  String matchesMetaCompatibilityShort(String value);

  /// Eşleşme kartı için ekran okuyucu etiketi.
  ///
  /// In tr, this message translates to:
  /// **'{name}, {rating} puan. {compatibility} rota uyumu. Kalkış {time}. Kişi başı {fare}.'**
  String matchesCardSemanticLabel(
    String name,
    String rating,
    String compatibility,
    String time,
    String fare,
  );

  /// İstatistik başlığı: Güven Puanı. Değer backend'e aittir, istemcide hesaplanmaz.
  ///
  /// In tr, this message translates to:
  /// **'Güven Puanı'**
  String get routeDetailsStatTrustScore;

  /// İstatistik başlığı: isteklerin onaylanma oranı.
  ///
  /// In tr, this message translates to:
  /// **'Onay oranı'**
  String get routeDetailsStatApprovalRate;

  /// İstatistik başlığı: paylaşılan toplam mesafe.
  ///
  /// In tr, this message translates to:
  /// **'km paylaşıldı'**
  String get routeDetailsStatSharedDistance;

  /// Üyelik yılı ve semt. Mock sunum verisidir.
  ///
  /// In tr, this message translates to:
  /// **'{year}\'ten beri üye · {area}'**
  String routeDetailsMemberSince(String year, String area);

  /// Başlıktaki puan ve yolculuk özeti.
  ///
  /// In tr, this message translates to:
  /// **'{rating} · {trips} yolculuk'**
  String routeDetailsRatingSummary(String rating, String trips);

  /// Rota zaman çizelgesinde kalkış noktasının açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Alış noktası'**
  String get routeDetailsPickupLabel;

  /// Rota zaman çizelgesinde varışın açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Varış · {minutes} dk'**
  String routeDetailsArrivalLabel(String minutes);

  /// Ortak bağlantı kartının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Ortak bağlantı'**
  String get routeDetailsMutualTitle;

  /// Maliyet paylaşımı etiketi. Bu bir ücret veya bilet değildir.
  ///
  /// In tr, this message translates to:
  /// **'Senin payın'**
  String get routeDetailsFareLabel;

  /// Mesaj düğmesi için ekran okuyucu etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Sürücüye mesaj gönder'**
  String get routeDetailsMessageSemanticLabel;

  /// Yolculuk isteği gönderme eylemi.
  ///
  /// In tr, this message translates to:
  /// **'İstek gönder'**
  String get routeDetailsRequestSeat;

  /// İstek gönderme henüz uygulanmadığı için gösterilen geçici bilgi mesajı. Hiçbir istek gönderilmez.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuk isteği özelliği yakında eklenecek.'**
  String get routeDetailsRequestUnavailable;

  /// Mesajlaşma henüz uygulanmadığı için gösterilen geçici bilgi mesajı.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlaşma özelliği yakında eklenecek.'**
  String get routeDetailsMessagingUnavailable;

  /// Geçersiz bir rota kimliği açıldığında gösterilen savunma amaçlı mesaj.
  ///
  /// In tr, this message translates to:
  /// **'Bu rota artık görüntülenemiyor.'**
  String get routeDetailsNotFound;

  /// Rota oluştur ekranının başlığı. Sürücünün kendi yolculuğunu paylaşmasıdır; ticari yolcu taşımacılığı değildir.
  ///
  /// In tr, this message translates to:
  /// **'Rota oluştur'**
  String get createRouteTitle;

  /// Rota oluştur başlığının altındaki açıklama.
  ///
  /// In tr, this message translates to:
  /// **'Sürücü olarak koltuk paylaş'**
  String get createRouteSubtitle;

  /// Kalkış noktası satırının ekran okuyucu etiketi. Tasarımda görsel bir NEREDEN etiketi yok, bu yüzden hangi uç olduğunu yalnızca bu etiket söyler.
  ///
  /// In tr, this message translates to:
  /// **'Kalkış: {place}'**
  String createRouteOriginSemanticLabel(String place);

  /// Varış noktası satırının ekran okuyucu etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Varış: {place}'**
  String createRouteDestinationSemanticLabel(String place);

  /// Kalkış noktası seçme sayfasının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Nereden yola çıkıyorsun?'**
  String get createRouteOriginPickerTitle;

  /// Varış noktası seçme sayfasının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Nereye gidiyorsun?'**
  String get createRouteDestinationPickerTitle;

  /// Yolculuğun hafta içi her gün tekrarlanmasını açıp kapatan anahtarın başlığı. Tasarımdaki tek tekrar seçeneğidir.
  ///
  /// In tr, this message translates to:
  /// **'Her hafta içi tekrarla'**
  String get createRouteRecurrenceTitle;

  /// Tekrar açıkken gösterilen özet. Yalnızca açıkken görünür; kapalıyken tasarımda bir karşılığı yoktur.
  ///
  /// In tr, this message translates to:
  /// **'Pzt–Cum · {time} kalkış'**
  String createRouteRecurrenceDetail(String time);

  /// Paylaşılan boş koltuk sayısı alanının üst etiketi.
  ///
  /// In tr, this message translates to:
  /// **'BOŞ KOLTUK'**
  String get createRouteSeatsLabel;

  /// Koltuk sayısı artır/azalt denetiminin ekran okuyucu etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Boş koltuk'**
  String get createRouteSeatsSemanticLabel;

  /// Koltuk sayısının ekran okuyucuya okunan değeri.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{1 koltuk} other{{count} koltuk}}'**
  String createRouteSeatsValue(int count);

  /// Kişi başına düşen maliyet payı alanının üst etiketi. Ücret veya fiyat değildir.
  ///
  /// In tr, this message translates to:
  /// **'KİŞİ BAŞI'**
  String get createRouteCostShareLabel;

  /// Maliyet payının altındaki açıklama. Gösterilen tutar sabit bir örnek değerdir; hiçbir hesaplamadan gelmez ve bu aşamada değiştirilemez.
  ///
  /// In tr, this message translates to:
  /// **'Önerilen · maliyet paylaşımı'**
  String get createRouteCostShareCaption;

  /// Maliyet payı kutusunun ekran okuyucu etiketi. Bir düğme değil, salt okunur bir bilgidir.
  ///
  /// In tr, this message translates to:
  /// **'Kişi başı önerilen maliyet paylaşımı: {amount}'**
  String createRouteCostShareSemanticLabel(String amount);

  /// Sürücünün yolculukla birlikte yayımladığı kuralların bölüm başlığı.
  ///
  /// In tr, this message translates to:
  /// **'YOLCULUK KURALLARI'**
  String get createRouteRulesTitle;

  /// Yolculuk kuralı. Aramadaki aynı adlı yolcu filtresinden ayrıdır: burada sürücünün ilan ettiği kuraldır.
  ///
  /// In tr, this message translates to:
  /// **'Sigara yok'**
  String get createRouteRuleNoSmoking;

  /// Yolculuk kuralı: müzik dinlenebilir.
  ///
  /// In tr, this message translates to:
  /// **'Müzik OK'**
  String get createRouteRuleMusicOk;

  /// Yolculuk kuralı. Politika açısından hassas bir tercihtir; istemci bundan bir uygunluk kuralı türetmez ve arka uçta uygulanmadan önce hukuk, erişilebilirlik ve ürün incelemesi gerekir.
  ///
  /// In tr, this message translates to:
  /// **'Evcil hayvan yok'**
  String get createRouteRuleNoPets;

  /// Yolculuk kuralı: sessiz yolculuk.
  ///
  /// In tr, this message translates to:
  /// **'Sessiz'**
  String get createRouteRuleQuiet;

  /// Rota oluştur ekranının ana eylemi.
  ///
  /// In tr, this message translates to:
  /// **'Rotayı yayınla'**
  String get createRoutePublish;

  /// Yayınla düğmesine basıldığında gösterilen geçici bilgi. Hiçbir rota oluşturulmadığını açıkça söylemelidir; başarı ya da 'yayınlandı' izlenimi vermemelidir.
  ///
  /// In tr, this message translates to:
  /// **'Rota henüz yayınlanmadı. Yayınlama özelliği yakında eklenecek.'**
  String get createRoutePublishUnavailable;

  /// Göreli tarih: bugün.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get dateToday;

  /// Göreli tarih: dün.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get dateYesterday;

  /// Göreli tarih: yarın.
  ///
  /// In tr, this message translates to:
  /// **'Yarın'**
  String get dateTomorrow;

  /// Göreli tarih: n gün önce.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{1 gün önce} other{{count} gün önce}}'**
  String dateDaysAgo(int count);

  /// Göreli tarih: n hafta önce.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{1 hafta önce} other{{count} hafta önce}}'**
  String dateWeeksAgo(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
