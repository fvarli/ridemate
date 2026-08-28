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

  /// Başarısız bir isteği yeniden başlatır. Önbellek yoktur; istek baştan yapılır.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden dene'**
  String get commonRetry;

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
  /// **'{name}, {rating} puan. {route}. Kişi başı {costShare}. {compatibility} rota uyumu.'**
  String homeMatchSemanticLabel(
    String name,
    String rating,
    String route,
    String costShare,
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
  /// **'{name}, {rating} puan. {compatibility} rota uyumu. Kalkış {time}. Kişi başı {costShare}.'**
  String matchesCardSemanticLabel(
    String name,
    String rating,
    String compatibility,
    String time,
    String costShare,
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

  /// Üyelik yılı ve semt. Mock sunum verisidir. UYARI: ekteki 'ten yalnızca mevcut 2023/2024 sabit değerleri için doğrudur; 2019 (2019'dan), 2020 ve 2021 ('den) yanlış çıkar. Doğrusu sayıyı okunuşuna çevirip ünlü uyumu uygulamayı gerektirir; iki durumluk bir if bu hatayı çözmez, saklar. Ertelenmiş: design-system.md §8.
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
  String get routeDetailsCostShareLabel;

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

  /// Kalkış henüz seçilmediğinde gösterilir. Sunucudan gelmeyen bir yer adı gösterilmez.
  ///
  /// In tr, this message translates to:
  /// **'Kalkış noktası seç'**
  String get createRouteOriginEmpty;

  /// Varış henüz seçilmediğinde gösterilir.
  ///
  /// In tr, this message translates to:
  /// **'Varış noktası seç'**
  String get createRouteDestinationEmpty;

  /// İki uç aynı yeri gösterdiğinde yayınlamaya basıldığında söylenir.
  ///
  /// In tr, this message translates to:
  /// **'Kalkış ve varış aynı yer olamaz.'**
  String get createRouteEndpointsSame;

  /// Sunucudan gelen yer listesi beklenirken gösterilir.
  ///
  /// In tr, this message translates to:
  /// **'Yerler yükleniyor…'**
  String get createRoutePlacesLoading;

  /// Sunucu boş bir katalog döndürdüğünde. Bilinen yerler istemcide uydurulmaz.
  ///
  /// In tr, this message translates to:
  /// **'Şu anda desteklenen bir yer yok.'**
  String get createRoutePlacesEmpty;

  /// Katalog okunamadığında. Yedek olarak sahte yer gösterilmez; seçim yapılamaz.
  ///
  /// In tr, this message translates to:
  /// **'Yer listesi alınamadı.'**
  String get createRoutePlacesUnavailable;

  /// Yolculuğun hafta içi her gün tekrarlanmasını açıp kapatan anahtarın başlığı. Tasarımdaki tek tekrar seçeneğidir.
  ///
  /// In tr, this message translates to:
  /// **'Her hafta içi tekrarla'**
  String get createRouteRecurrenceTitle;

  /// Tekrar açıkken gösterilen gün aralığı. Kalkış saati kendi alanında gösterilir; burada tekrarlanmaz.
  ///
  /// In tr, this message translates to:
  /// **'Pzt–Cum'**
  String get createRouteRecurrenceDetail;

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

  /// Tek seferlik yolculuğun tarih alanının üst etiketi.
  ///
  /// In tr, this message translates to:
  /// **'GİDİŞ TARİHİ'**
  String get createRouteDepartureDateLabel;

  /// Henüz tarih seçilmediğinde gösterilir. Örnek bir tarih göstermek, seçilmiş bir tarihten ayırt edilemezdi.
  ///
  /// In tr, this message translates to:
  /// **'Tarih seç'**
  String get createRouteDepartureDateEmpty;

  /// Kalkış saati alanının üst etiketi. Her iki tekrar seçeneğinde de gereklidir.
  ///
  /// In tr, this message translates to:
  /// **'GİDİŞ SAATİ'**
  String get createRouteDepartureTimeLabel;

  /// Henüz saat seçilmediğinde gösterilir.
  ///
  /// In tr, this message translates to:
  /// **'Saat seç'**
  String get createRouteDepartureTimeEmpty;

  /// Tek seferlik yolculuk tarihsiz yayınlanamaz.
  ///
  /// In tr, this message translates to:
  /// **'Gidiş tarihi seç.'**
  String get createRouteDepartureDateMissing;

  /// Kalkış saati seçilmeden yolculuk yayınlanamaz.
  ///
  /// In tr, this message translates to:
  /// **'Gidiş saati seç.'**
  String get createRouteDepartureTimeMissing;

  /// Sunucu yolculuğu kabul ettikten sonra gösterilir. Yalnızca sunucu onayladıktan sonra söylenir.
  ///
  /// In tr, this message translates to:
  /// **'Rotan yayınlandı.'**
  String get createRoutePublished;

  /// Sonucu belirsiz kalan bir denemeden sonra başlık. Ayrıntı RmErrorCopy'den gelir.
  ///
  /// In tr, this message translates to:
  /// **'Rota yayınlanamadı.'**
  String get createRoutePublishFailed;

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

  /// Harita üstündeki canlı yolculuk rozeti. Yalnızca görsel bir işarettir; arkasında gerçek bir konum takibi yoktur.
  ///
  /// In tr, this message translates to:
  /// **'CANLI YOLCULUK'**
  String get activeTripLiveBadge;

  /// Varış bilgisinin üst satırı. Varış noktası Türkçe yönelme ekiyle birlikte tek bir metin olarak tutulur; ek, sesli uyuma göre değiştiği için yer adı yer tutucu yapılmaz.
  ///
  /// In tr, this message translates to:
  /// **'Levent\'e varış'**
  String get activeTripEtaLabel;

  /// Kalan süre ve mesafe. İkisi de sabit örnek değerlerdir; hiçbir hesaplamadan gelmez.
  ///
  /// In tr, this message translates to:
  /// **'{duration} {distance}'**
  String activeTripEtaValue(String duration, String distance);

  /// Yolculuğun gecikme durumu. Tasarımda yalnızca bu tek durum çizilmiştir.
  ///
  /// In tr, this message translates to:
  /// **'Zamanında'**
  String get activeTripOnTime;

  /// Varış bloğunun ekran okuyucu etiketi.
  ///
  /// In tr, this message translates to:
  /// **'{label}, {duration}, {distance}, {status}'**
  String activeTripEtaSemanticLabel(
    String label,
    String duration,
    String distance,
    String status,
  );

  /// Sürücü satırının ekran okuyucu etiketi. Bu ekranda çevrimiçi bilgisini yazan görünür bir metin olmadığı için, avatardaki nokta yerine bu etiket taşır. Çevrimiçi durumu kimlik doğrulamasından ayrı bir kavramdır.
  ///
  /// In tr, this message translates to:
  /// **'{name}, {rating} puan, çevrimiçi. {vehicle}, {plate}.'**
  String activeTripDriverSemanticLabel(
    String name,
    String rating,
    String vehicle,
    String plate,
  );

  /// Sürücü satırındaki araç ve plaka.
  ///
  /// In tr, this message translates to:
  /// **'{vehicle} · {plate}'**
  String activeTripDriverMeta(String vehicle, String plate);

  /// Sürücü adı ve puanı, tasarımdaki gibi tek satırda.
  ///
  /// In tr, this message translates to:
  /// **'{name} · {rating}'**
  String activeTripDriverName(String name, String rating);

  /// Sürücüyü arama düğmesinin ekran okuyucu etiketi. Telefon araması özelliği yoktur.
  ///
  /// In tr, this message translates to:
  /// **'Sürücüyü ara'**
  String get activeTripCall;

  /// Sohbeti açan düğmenin ekran okuyucu etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Sürücüye mesaj gönder'**
  String get activeTripMessage;

  /// Yolculuğu paylaşma düğmesi. Paylaşım özelliği henüz yoktur.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuğu paylaş'**
  String get activeTripShare;

  /// Acil durum işareti. Hem Aktif Yolculuk düğmesinde hem Güvenlik Merkezi kartında kullanılır; arkasında hiçbir acil durum akışı yoktur.
  ///
  /// In tr, this message translates to:
  /// **'SOS'**
  String get sosLabel;

  /// SUNUM METNİ — GERÇEK DEĞİL. Tasarımdaki alt bilgi satırı. Hiçbir konum paylaşılmıyor, hiçbir acil kişiye ulaşılmıyor, arka planda konum takibi yok. Bu yüzden ekran yalnızca hata ayıklama derlemesinde açılabilir ve bu metin yayına çıkan hiçbir ekranda kullanılamaz.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{Canlı konumun 1 acil kişiyle paylaşılıyor} other{Canlı konumun {count} acil kişiyle paylaşılıyor}}'**
  String activeTripLocationSharing(int count);

  /// Yolculuğu paylaş düğmesine basıldığında gösterilen geçici bilgi. Hiçbir şeyin paylaşılmadığını açıkça söylemelidir.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuk paylaşma özelliği henüz aktif değil. Hiçbir şey paylaşılmadı.'**
  String get activeTripShareUnavailable;

  /// Arama düğmesine basıldığında gösterilen geçici bilgi.
  ///
  /// In tr, this message translates to:
  /// **'Arama özelliği henüz aktif değil. Hiçbir arama başlatılmadı.'**
  String get activeTripCallUnavailable;

  /// SOS öğesine basıldığında gösterilen geçici bilgi. Kimseye ulaşılmadığını açıkça söylemelidir. Aktif Yolculuk ve Güvenlik Merkezi aynı kavramı paylaştığı için ikisi de bu tek metni kullanır. Acil durum numarası veya başka bir yönlendirme eklenmez; gerçek acil durum akışı ayrı bir aşamada tasarlanacaktır.
  ///
  /// In tr, this message translates to:
  /// **'Acil durum özelliği henüz aktif değil. Kimseye bildirim gönderilmedi.'**
  String get sosUnavailable;

  /// Sohbet başlığındaki çevrimiçi bilgisi. Sunum verisidir; gerçek bir çevrimiçi durumu servisi yoktur. Kimlik doğrulamasından ayrı bir kavramdır.
  ///
  /// In tr, this message translates to:
  /// **'Çevrimiçi'**
  String get chatOnline;

  /// Sohbet başlığının ekran okuyucu etiketi. Doğrulama ve çevrimiçi durumu ayrı ayrı ve birer kez okunur; ikisi farklı kavramlardır.
  ///
  /// In tr, this message translates to:
  /// **'{name}, kimliği doğrulanmış, çevrimiçi'**
  String chatHeaderSemanticLabel(String name);

  /// Sohbetin üstündeki güvenlik uyarısı. Tasarımdaki metin uygulama içi ödeme yapılmasını söylüyor; RideMate'te henüz ödeme özelliği olmadığı ve bu ekran yayına çıktığı için, uyarının güvenlik amacı korunarak olmayan bir özelliğe işaret etmeyen geçici metin kullanılır. Ödeme gerçekten geldiğinde tasarımdaki metin geri alınacaktır.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme özelliği henüz aktif değil. Kişisel veya finansal bilgilerinizi paylaşmayın.'**
  String get chatSafetyBanner;

  /// Örnek konuşmanın ilk mesajı, sürücüden. Sunum verisidir.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba Elif! Yarın 08:25\'te Kadıköy İskele\'de olurum 👍'**
  String get chatMessageIncoming;

  /// Örnek konuşmanın ikinci mesajı, üyeden.
  ///
  /// In tr, this message translates to:
  /// **'Harika, teşekkürler! Ben de orada olacağım.'**
  String get chatMessageOutgoing;

  /// Örnek konuşmanın son mesajı, üyeden.
  ///
  /// In tr, this message translates to:
  /// **'Görüşürüz 🙌'**
  String get chatMessageOutgoingClosing;

  /// Konum paylaşımı kartının etiketi. Emoji tasarımdan gelir ve metnin anlamı emoji olmadan da tamdır.
  ///
  /// In tr, this message translates to:
  /// **'📍 Buluşma noktası'**
  String get chatLocationLabel;

  /// Konum kartının ekran okuyucu etiketi. Kart bir yere gitmez; düğme değildir.
  ///
  /// In tr, this message translates to:
  /// **'{name} konum paylaştı: {label}'**
  String chatLocationSemanticLabel(String name, String label);

  /// Mesaj balonunun ekran okuyucu etiketi. Kimin konuştuğu yalnızca hizalama ve renkle belli olduğu için etikete yazılır.
  ///
  /// In tr, this message translates to:
  /// **'{speaker}: {text}'**
  String chatBubbleSemanticLabel(String speaker, String text);

  /// Ekran okuyucuda üyenin kendi mesajlarını tanımlayan sözcük.
  ///
  /// In tr, this message translates to:
  /// **'Sen'**
  String get chatSpeakerSelf;

  /// Hazır yanıt. Dokunmak metni yazma alanına ekler; mesaj göndermez.
  ///
  /// In tr, this message translates to:
  /// **'Yoldayım'**
  String get chatQuickReplyOnMyWay;

  /// Hazır yanıt. Dokunmak metni yazma alanına ekler; mesaj göndermez.
  ///
  /// In tr, this message translates to:
  /// **'5 dk geç'**
  String get chatQuickReplyRunningLate;

  /// Yazma alanının ipucu metni.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj yaz…'**
  String get chatComposerHint;

  /// Yazma alanının kalıcı ekran okuyucu etiketi. İpucu metni odaklanınca kaybolduğu için ayrı bir etiket gerekir.
  ///
  /// In tr, this message translates to:
  /// **'Mesajını yaz'**
  String get chatComposerLabel;

  /// Gönder düğmesinin ekran okuyucu etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get chatSend;

  /// Gönder düğmesine basıldığında gösterilen geçici bilgi. Mesajın gönderilmediğini açıkça söylemelidir; yazılan metin alanda kalır ve konuşmaya hiçbir şey eklenmez.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj gönderilmedi. Mesajlaşma özelliği henüz eklenmedi.'**
  String get chatSendUnavailable;

  /// Profil başlığındaki üyelik rozeti. Yıl bilerek parametre DEĞİLDİR: Türkçede ekin biçimi sayının okunuşuna bağlıdır ve değişkene ek yapıştırmak yanlış sonuç verir. Mock sunum verisidir; hiçbir hesap veya doğrulama sistemi yoktur.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanmış üye · 2024\'ten beri'**
  String get profileMemberBadge;

  /// Güven Puanı kartının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Güven Puanı'**
  String get profileTrustScoreTitle;

  /// Halkanın ortasında puanın altında görünen ölçek.
  ///
  /// In tr, this message translates to:
  /// **'/ 100'**
  String get profileTrustScoreOutOf;

  /// Yüzdelik dilim rozeti. Gerçek bir üye kitlesi olmadığı için tamamen sunum verisidir; hiçbir sıralama hesaplanmaz.
  ///
  /// In tr, this message translates to:
  /// **'Üst {percentile} · Güvenilir'**
  String profileTrustTier(String percentile);

  /// Tasarımdaki cümle, olduğu gibi. PARAMETRE EKLEMEYİN: '1 yolculuk' sayısını değişkene çevirmek, yolculuk başına puan diye bir kural olduğunu varsaymak olur. Böyle bir kural yok.
  ///
  /// In tr, this message translates to:
  /// **'100\'e ulaşmak için 1 yolculuk daha'**
  String get profileTrustNextStep;

  /// Güven Puanı dökümü satırı.
  ///
  /// In tr, this message translates to:
  /// **'Kimlik'**
  String get profileTrustFactorIdentity;

  /// Güven Puanı dökümü satırı.
  ///
  /// In tr, this message translates to:
  /// **'Topluluk'**
  String get profileTrustFactorCommunity;

  /// Güven Puanı dökümü satırı.
  ///
  /// In tr, this message translates to:
  /// **'Güvenilirlik'**
  String get profileTrustFactorReliability;

  /// Güven Puanı dökümü satırı.
  ///
  /// In tr, this message translates to:
  /// **'Aktiflik'**
  String get profileTrustFactorActivity;

  /// İstatistik kutusu etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuk'**
  String get profileStatTrips;

  /// İstatistik kutusu etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Puan'**
  String get profileStatRating;

  /// İstatistik kutusu etiketi. Masraf paylaşımı sunumudur; uygulamada ödeme yoktur.
  ///
  /// In tr, this message translates to:
  /// **'Tasarruf'**
  String get profileStatSavings;

  /// Profil listesi satırı. Tasarımda dokunulabilir değildir ve bir yere gitmez.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama rozetleri'**
  String get profileVerificationBadges;

  /// Profil listesi satırı; değerlendirmeler ekranını açar.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirmelerim'**
  String get profileMyReviews;

  /// Halkanın ekran okuyucu metni. Puanın nasıl oluştuğunu ima eden hiçbir ifade EKLEMEYİN; bir hesap yöntemi yoktur.
  ///
  /// In tr, this message translates to:
  /// **'Güven Puanı: {score}, 100 üzerinden'**
  String profileTrustScoreSemanticLabel(String score);

  /// Döküm satırının ekran okuyucu metni.
  ///
  /// In tr, this message translates to:
  /// **'{label}: {value}'**
  String profileTrustFactorSemanticLabel(String label, String value);

  /// Amber satırın ekran okuyucu metni. Uyarıyı yalnızca renk taşımasın diye vardır (WCAG 1.4.1).
  ///
  /// In tr, this message translates to:
  /// **'{label}: {value}, dikkat'**
  String profileTrustFactorAttentionSemanticLabel(String label, String value);

  /// Rozet sayısı yalnızca trailing rozette yazdığı için satırın etiketi elle verilir; yoksa sayı hiç okunmaz.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama rozetleri: {total} adımdan {done} tanesi tamamlandı'**
  String profileVerificationBadgesSemanticLabel(String done, String total);

  /// Değerlendirmeler ekranının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirmeler'**
  String get reviewsTitle;

  /// Toplam değerlendirme sayısı. Tasarım iki kart gösterip 73 yazar; bu çelişki bilerek korunmuştur, design-system.md §8.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{{count} değerlendirme}}'**
  String reviewsCount(int count);

  /// Değerlendirme etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Dakik'**
  String get reviewsTagPunctual;

  /// Değerlendirme etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Güvenli sürüş'**
  String get reviewsTagSafeDriving;

  /// Değerlendirme etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Güler yüzlü'**
  String get reviewsTagFriendly;

  /// Değerlendirme etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Temiz araç'**
  String get reviewsTagCleanCar;

  /// Etiket ve kaç değerlendirmede geçtiği. Sayılar toplamı değerlendirme sayısını aşar; bir değerlendirme birden çok etiket taşır.
  ///
  /// In tr, this message translates to:
  /// **'{label} · {count}'**
  String reviewsTagLabel(String label, String count);

  /// Değerlendirme kartındaki bağlam metni. Bir rota değil, yolculuğun düzenliliğidir.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli rota'**
  String get reviewsContextRegularRoute;

  /// Tasarımdaki örnek değerlendirme metni, olduğu gibi. Mock sunum verisidir.
  ///
  /// In tr, this message translates to:
  /// **'Çok güvenli ve dakik bir yolculuktu. Selin gerçekten güler yüzlü, kesinlikle tekrar tercih ederim.'**
  String get reviewsMockBodyFirst;

  /// Tasarımdaki örnek değerlendirme metni, olduğu gibi. Mock sunum verisidir.
  ///
  /// In tr, this message translates to:
  /// **'Her sabah aynı saatte, tertemiz araç. Trafikte sohbet etmek güzel.'**
  String get reviewsMockBodySecond;

  /// Yıldız sırasının ekran okuyucu metni. Beş yıldız beş kez okunmasın diye tek düğümde toplanır.
  ///
  /// In tr, this message translates to:
  /// **'5 üzerinden {rating}'**
  String reviewsRatingSemanticLabel(String rating);

  /// Histogram satırının ekran okuyucu metni. Oran olduğu açıkça söylenir; yoksa çubuğun kendi sayısı değerlendirme adedi sanılır.
  ///
  /// In tr, this message translates to:
  /// **'{stars} yıldız: değerlendirmelerin {share} kadarı'**
  String reviewsDistributionSemanticLabel(String stars, String share);

  /// Değerlendirme kartının ekran okuyucu metni; yoksa baş harfler harf harf okunur ve puan bağlamsız kalır.
  ///
  /// In tr, this message translates to:
  /// **'{author}, {age}, {context}. {rating}. {body}'**
  String reviewsEntrySemanticLabel(
    String author,
    String age,
    String context,
    String rating,
    String body,
  );

  /// Güvenlik Merkezi ekranının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik Merkezi'**
  String get safetyTitle;

  /// Başlık altındaki tanıtım satırı.
  ///
  /// In tr, this message translates to:
  /// **'Her yolculukta yanındayız'**
  String get safetySubtitle;

  /// SOS kartının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Acil yardım'**
  String get safetySosTitle;

  /// SUNUM METNİ — GERÇEK DEĞİL. Tasarımdaki söz, olduğu gibi. Basıldığında hiçbir konum gönderilmez, hiçbir kişiye ulaşılmaz, bir ekip yoktur. Bu yüzden ekran yalnızca hata ayıklama derlemesinde açılabilir ve bu metin yayına çıkan hiçbir ekranda kullanılamaz. Koyu tema kopyası bu cümleyi kısaltır; tek metin iki temaya da hizmet ettiği için kapsayıcı olan bu sürüm kullanılır (D-safety-2).
  ///
  /// In tr, this message translates to:
  /// **'Bas, konumun ve yolculuk bilgin acil kişilere + ekibimize gider.'**
  String get safetySosPromise;

  /// Hızlı işlem kutusu. Uygulama telefon araması başlatamaz; basıldığında bunu söyleyen bir metin gösterilir. Numara tasarımdan gelir ve pazara göre değişmesi gereken bir üründür — design-system.md §8.
  ///
  /// In tr, this message translates to:
  /// **'112\'yi ara'**
  String get safetyCallEmergencyTitle;

  /// Hızlı işlem kutusunun alt satırı.
  ///
  /// In tr, this message translates to:
  /// **'Acil servis'**
  String get safetyCallEmergencyCaption;

  /// Hızlı işlem kutusu. Paylaşım özelliği yoktur.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuğu paylaş'**
  String get safetyShareTripTitle;

  /// SUNUM METNİ — GERÇEK DEĞİL. Canlı konum diye bir özellik yoktur.
  ///
  /// In tr, this message translates to:
  /// **'Canlı konum'**
  String get safetyShareTripCaption;

  /// Hızlı işlem kutusunun ekran okuyucu metni; ekranda yazanla aynı olmalıdır.
  ///
  /// In tr, this message translates to:
  /// **'{title}. {caption}'**
  String safetyQuickActionSemanticLabel(String title, String caption);

  /// Liste satırı. Arkasındaki düzenleme ekranı tasarlanmamıştır.
  ///
  /// In tr, this message translates to:
  /// **'Güvenilir kişiler'**
  String get safetyTrustedContactsTitle;

  /// SUNUM METNİ — GERÇEK DEĞİL. Hiçbir kişi saklanmıyor; ortada bir kişi listesi yoktur. Güvenlik Merkezi yayına açılırsa değişmesi gereken ilk metin budur.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{1 kişi eklendi} other{{count} kişi eklendi}}'**
  String safetyTrustedContactsSubtitle(int count);

  /// Liste satırı. Arkasındaki tarayıcı tasarlanmamıştır.
  ///
  /// In tr, this message translates to:
  /// **'Yol arkadaşını doğrula'**
  String get safetyVerifyPartnerTitle;

  /// Liste satırının alt metni. Kamera izni, tarayıcı veya kimlik doğrulama sağlayıcısı yoktur.
  ///
  /// In tr, this message translates to:
  /// **'QR ile kimlik eşleştir'**
  String get safetyVerifyPartnerSubtitle;

  /// Liste satırı. Tek bir işlem mi iki işlem mi olduğu, engellemenin mevcut eşleşme ve sohbetlere ne yaptığı ürün ve hukuk sorusudur; burada varsayılmaz. Koyu tema kopyası bu satırı hiç çizmez; güvenlik seçeneğinin gece kaybolması bir gerileme olduğu için satır iki temada da durur (D-safety-2).
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı engelle / bildir'**
  String get safetyBlockReportTitle;

  /// Liste satırının alt metni. Tasarımdan alınmıştır; işletme karşılığı tanımlı değildir.
  ///
  /// In tr, this message translates to:
  /// **'Gizli inceleme'**
  String get safetyBlockReportSubtitle;

  /// 112 kutusuna basıldığında gösterilen geçici bilgi. Eksik olan yetenek açıkça söylenir. tel: bağlantısı, url_launcher, platform kanalı, izin veya çevirici tümleştirmesi YOKTUR.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama henüz arama başlatamıyor.'**
  String get safetyCallUnavailable;

  /// Geçici bilgi. Kişi eklenmez, izin istenmez, kimseye bildirim gitmez.
  ///
  /// In tr, this message translates to:
  /// **'Güvenilir kişiler özelliği henüz eklenmedi.'**
  String get safetyTrustedContactsUnavailable;

  /// Geçici bilgi. Kamera açılmaz, izin istenmez, QR üretilmez veya okunmaz.
  ///
  /// In tr, this message translates to:
  /// **'QR ile doğrulama özelliği henüz eklenmedi.'**
  String get safetyVerifyPartnerUnavailable;

  /// Geçici bilgi. Hiç kimse engellenmez ve hiçbir bildirim kaydedilmez. Sahte bir engelleme durumu saklamak, kişinin korunduğunu sanmasına yol açacağı için uygulamadaki en tehlikeli prototip durumu olurdu.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı engelleme özelliği henüz eklenmedi.'**
  String get safetyBlockReportUnavailable;

  /// Yönlendirme hatası ekranının başlığı. Tasarımda hata durumu çizilmemiştir; token dilinden türetilmiştir.
  ///
  /// In tr, this message translates to:
  /// **'Bir şeyler ters gitti'**
  String get errorTitle;

  /// Genel hata metni. Kullanıcıya teknik ayrıntı GÖSTERİLMEZ: istisna metni, yığın izi, denenen adres veya hata kodu buraya asla girmez. Ayrıntılar yalnızca hata raporlama noktasına gider.
  ///
  /// In tr, this message translates to:
  /// **'Bu sayfa açılamadı. Ana sayfaya dönüp tekrar deneyebilirsin.'**
  String get errorBody;

  /// Hata ekranındaki tek kurtarma eylemi. Ana sayfa her zaman vardır; çözülmeyebilecek bir eylem sunmak ikinci bir hata olurdu.
  ///
  /// In tr, this message translates to:
  /// **'Ana sayfaya dön'**
  String get errorReturnHome;

  /// Mesajlar sekmesi. Tasarımda sohbet listesi ekranı hiç çizilmemiştir; tek örnek sohbeti burada göstermek, sabit bir konuşmayı kullanıcının tüm gelen kutusu gibi sunmak olurdu. Yayına ulaşan bir yüzey olduğu için metin çevrilebilir olmalıdır — design-system.md §8.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet listesi henüz eklenmedi.'**
  String get messagesPlaceholderBody;

  /// Ana ekrandaki kayıtlı adres kısayollarına basıldığında gösterilen geçici bilgi. Kayıtlı adres diye bir kavram, saklama veya arka uç yoktur; hiçbir arama başlatılmaz ve hiçbir yere gidilmez.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı adres özelliği henüz eklenmedi.'**
  String get homeShortcutUnavailable;

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

  /// Ağ hatası. Sunucuya hiç ulaşılamadığında gösterilir.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı kurulamadı. İnternet bağlantını kontrol et.'**
  String get errorNetwork;

  /// 409. İstek, sunucudaki mevcut durumla bağdaşmıyor. Sessizce yeni bir kimlikle tekrar denenmez.
  ///
  /// In tr, this message translates to:
  /// **'Bu rota zaten yayınlanmış görünüyor.'**
  String get errorConflict;

  /// Tanınmayan veya beklenmeyen sunucu hatası için güvenli varsayılan metin.
  ///
  /// In tr, this message translates to:
  /// **'Beklenmeyen bir sorun oluştu. Lütfen tekrar dene.'**
  String get errorUnexpected;

  /// Sunucu gönderilen veriyi reddettiğinde.
  ///
  /// In tr, this message translates to:
  /// **'Girdiğin bilgileri kontrol et.'**
  String get errorValidation;

  /// Kimlik doğrulama geçersiz veya süresi dolmuş.
  ///
  /// In tr, this message translates to:
  /// **'Oturumun sona erdi. Tekrar giriş yap.'**
  String get errorUnauthenticated;

  /// Kimlik bilgisi geçerli ama hesap kullanılamıyor. Tekrar giriş yapmak çözmez.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın askıya alındı.'**
  String get errorForbidden;

  /// Hız sınırına takıldı. Sunucu ne kadar beklenmesi gerektiğini bildirmez.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla deneme yapıldı. Biraz sonra tekrar dene.'**
  String get errorRateLimited;

  /// Telefon giriş ekranı başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numaran'**
  String get authPhoneTitle;

  /// Telefon giriş ekranı açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Sana altı haneli bir doğrulama kodu göndereceğiz.'**
  String get authPhoneBody;

  /// Telefon alanının kalıcı etiketi. İpucu odakta kaybolduğu için erişilebilir ad budur.
  ///
  /// In tr, this message translates to:
  /// **'Telefon numarası'**
  String get authPhoneFieldLabel;

  /// Telefon alanı ipucu. Örnek biçim; başka bir biçim de kabul edilir.
  ///
  /// In tr, this message translates to:
  /// **'0532 123 45 67'**
  String get authPhoneFieldHint;

  /// Numara gönderilmeden önce cihazda geçersiz bulundu.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir telefon numarası gir.'**
  String get authPhoneInvalid;

  /// Telefon ekranındaki birincil eylem.
  ///
  /// In tr, this message translates to:
  /// **'Kod gönder'**
  String get authPhoneSubmit;

  /// Kod giriş ekranı başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulama kodu'**
  String get authCodeTitle;

  /// Kod giriş ekranı açıklaması. Numara üyenin yazdığı biçimde gösterilir.
  ///
  /// In tr, this message translates to:
  /// **'{phone} numarasına gönderilen kodu gir.'**
  String authCodeBody(String phone);

  /// Kod alanının kalıcı etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Altı haneli kod'**
  String get authCodeFieldLabel;

  /// Sunucu kodu reddetti. Kaç deneme kaldığı bildirilmez.
  ///
  /// In tr, this message translates to:
  /// **'Kod doğru değil. Tekrar dene.'**
  String get authCodeInvalid;

  /// Kod ekranındaki birincil eylem.
  ///
  /// In tr, this message translates to:
  /// **'Doğrula'**
  String get authCodeSubmit;

  /// Yeni bir kod ister. Geri sayım yoktur: sunucu ne zaman izin vereceğini bildirmez, uydurulmuş bir sayaç yanlış olurdu.
  ///
  /// In tr, this message translates to:
  /// **'Kodu tekrar gönder'**
  String get authCodeResend;

  /// Tekrar gönderme isteği kabul edildi.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bir kod gönderildi.'**
  String get authCodeResent;

  /// Yayınlanan rotalar ekranının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Rotalarım'**
  String get myRoutesTitle;

  /// Profil listesi satırı; yayınlanan rotalar ekranını açar.
  ///
  /// In tr, this message translates to:
  /// **'Rotalarım'**
  String get profileMyRoutes;

  /// Sürücünün sunduğu koltuk sayısı. Kalan/boş koltuk DEĞİLDİR: sunucu koltuk isteklerini henüz bilmiyor, dolayısıyla müsaitlik iddiası edilemez.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{1 koltuk sunuluyor} other{{count} koltuk sunuluyor}}'**
  String myRoutesSeatsOffered(int count);

  /// Hafta içi tekrarlanan bir rotanın kart üzerindeki ifadesi.
  ///
  /// In tr, this message translates to:
  /// **'Her hafta içi'**
  String get myRoutesRecurrenceWeekdays;

  /// Rota hâlâ geçerli.
  ///
  /// In tr, this message translates to:
  /// **'Yayında'**
  String get myRoutesStatusPublished;

  /// Rota geri çekildi. Listeden silinmez; geçmiş korunur.
  ///
  /// In tr, this message translates to:
  /// **'İptal edildi'**
  String get myRoutesStatusCancelled;

  /// Tek seferlik bir rotanın kalkışı geçti. Bu değer sunucudan gelir; istemci hesaplamaz.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get myRoutesStatusPast;

  /// Hiç rota yokken gösterilir. Uydurma bir örnek rota gösterilmez.
  ///
  /// In tr, this message translates to:
  /// **'Henüz rota yayınlamadın'**
  String get myRoutesEmptyTitle;

  /// Boş durumun açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Yayınladığın rotalar burada görünür.'**
  String get myRoutesEmptyBody;

  /// Sonraki sayfayı ister. Yalnızca sunucu devam edilecek bir konum bildirdiğinde görünür.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla yükle'**
  String get myRoutesLoadMore;

  /// Sonraki sayfa gelmedi. Zaten yüklenmiş rotalar ekranda kalır.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki sayfa yüklenemedi.'**
  String get myRoutesLoadMoreFailed;

  /// Bir rotayı geri çeker. Yalnızca sunucu rotayı yayında VE kalkışı gelecekte bildirdiğinde görünür.
  ///
  /// In tr, this message translates to:
  /// **'Rotayı iptal et'**
  String get myRoutesCancel;

  /// İptal onay sayfasının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Bu rota iptal edilsin mi?'**
  String get myRoutesCancelConfirmTitle;

  /// Neyin iptal edileceğini adıyla söyler ve kaydın silinmediğini belirtir.
  ///
  /// In tr, this message translates to:
  /// **'{route} rotası yayından kalkar. Geçmişinde kalmaya devam eder.'**
  String myRoutesCancelConfirmBody(String route);

  /// Onay sayfasındaki yıkıcı eylem.
  ///
  /// In tr, this message translates to:
  /// **'Evet, iptal et'**
  String get myRoutesCancelConfirm;

  /// Onay sayfasını hiçbir şey yapmadan kapatır.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get myRoutesCancelDismiss;

  /// Sunucu iptali onayladıktan sonra gösterilir; önce değil.
  ///
  /// In tr, this message translates to:
  /// **'Rota iptal edildi.'**
  String get myRoutesCancelled;

  /// Bir rota kartının ekran okuyucuya okunan tam hâli.
  ///
  /// In tr, this message translates to:
  /// **'{route}, {departure}, {seats}, {status}'**
  String myRoutesCardSemanticLabel(
    String route,
    String departure,
    String seats,
    String status,
  );

  /// İptal düğmesinin hangi rotaya ait olduğunu söyler.
  ///
  /// In tr, this message translates to:
  /// **'{route} rotasını iptal et'**
  String myRoutesCancelSemanticLabel(String route);
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
