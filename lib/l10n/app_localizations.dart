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

  /// Yeniden okuma başarısız oldu. Önceki yanıt ekranda kalır ve güncel olduğu iddia edilmez. Yeniden denemek için liste aşağı çekilir.
  ///
  /// In tr, this message translates to:
  /// **'Yenilenemedi. Gösterilenler güncel olmayabilir.'**
  String get commonRefreshFailed;

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

  /// Üyenin KENDİ adıyla selamlanması. Ad sunucudan gelir; yüklenemezse adsız selam kullanılır, tahmin edilmez.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba, {name}'**
  String homeGreetingNamed(String name);

  /// Ana ekranın tek birincil eylemi. Arama ekranını açar; doğrudan sonuç listesine atlamaz.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuk bul'**
  String get homeFindRide;

  /// Birincil eylemin ekran okuyucu etiketi. Ne yaptığını söyler.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuk bul. Aramayı açar.'**
  String get homeFindRideSemanticLabel;

  /// Sunucunun /me/journeys ile döndürdüğü yolculukların başlığı. 'Bugün' veya 'sıradaki' DEMEZ: bu listenin neyi içerdiğine sunucu karar verir ve dün başlamış, hâlâ süren bir yolculuk da buradadır.
  ///
  /// In tr, this message translates to:
  /// **'Sürdüğün yolculuklar'**
  String get homeDrivingTitle;

  /// Üyenin gönderdiği koltuk isteklerinin önizlemesi. Onaylanmış yolculuk veya rezervasyon DEĞİLDİR.
  ///
  /// In tr, this message translates to:
  /// **'Koltuk isteklerin'**
  String get homeRequestsTitle;

  /// Önizlemeden tam listeye giden bağlantı.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get homeSeeAll;

  /// Gerçek yüzeylere giden bağlantıların başlığı. Kendi başına veri göstermez.
  ///
  /// In tr, this message translates to:
  /// **'Yönet'**
  String get homeManageTitle;

  /// Bir istek satırının ekran okuyucuda tek parça okunması. Durum sunucunun söylediğidir.
  ///
  /// In tr, this message translates to:
  /// **'{route}, {date}, {status}'**
  String homeRequestSemanticLabel(String route, String date, String status);

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

  /// Rota detayındaki ortak rota sayısı. Fixture ekranına ait.
  ///
  /// In tr, this message translates to:
  /// **'{count} ortak rota'**
  String matchesMetaSharedRoutes(String count);

  /// Sonuç listesinin başlığı. Sayı iddiası içermez.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuklar'**
  String get discoveryTitle;

  /// Aramayı başlatan buton.
  ///
  /// In tr, this message translates to:
  /// **'Yolculukları ara'**
  String get searchSubmit;

  /// İki uç nokta seçilmeden arama yapılamayacağını söyleyen metin.
  ///
  /// In tr, this message translates to:
  /// **'İki farklı yer seç.'**
  String get searchIncomplete;

  /// Henüz arama yapılmadığında görünen metin.
  ///
  /// In tr, this message translates to:
  /// **'Nereden nereye gittiğini seç.'**
  String get discoveryIdle;

  /// Arama sonucu boş olduğunda görünen metin.
  ///
  /// In tr, this message translates to:
  /// **'Bu iki yer arasında yayınlanmış yolculuk yok.'**
  String get discoveryEmpty;

  /// Boş sonuç açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Daha sonra tekrar bak ya da başka bir güzergah dene.'**
  String get discoveryEmptyBody;

  /// Listenin sırasını dürüstçe anlatan başlık. Puan ya da uyum sıralaması değildir.
  ///
  /// In tr, this message translates to:
  /// **'En son yayınlananlar önce'**
  String get discoveryOrdering;

  /// Sürücünün sunduğu koltuk sayısı. Kalan koltuk DEĞİLDİR.
  ///
  /// In tr, this message translates to:
  /// **'{count} koltuk sunuluyor'**
  String discoverySeatsOffered(int count);

  /// Sonraki sonuç sayfasını getiren buton.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla göster'**
  String get discoveryLoadMore;

  /// Sonraki sayfa alınamadığında görünen metin.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazlası alınamadı.'**
  String get discoveryLoadMoreFailed;

  /// Sürücüden bir koltuk isteme eylemi. İstek sunucuya gönderilir; onay sürücüye aittir.
  ///
  /// In tr, this message translates to:
  /// **'Koltuk iste'**
  String get seatRequestAsk;

  /// İstek sunucuya gönderilirken düğmenin durumu. Henüz gönderildiği iddia edilmez.
  ///
  /// In tr, this message translates to:
  /// **'Gönderiliyor…'**
  String get seatRequestSending;

  /// Sunucunun onayladığı durum: istek iletildi, sürücü henüz yanıtlamadı.
  ///
  /// In tr, this message translates to:
  /// **'İstek gönderildi'**
  String get seatRequestPending;

  /// Sürücü koltuğu paylaşmayı kabul etti. Ödeme veya rezervasyon DEĞİLDİR.
  ///
  /// In tr, this message translates to:
  /// **'Kabul edildi'**
  String get seatRequestAccepted;

  /// Sürücü isteği yanıtladı ve kabul etmedi.
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get seatRequestDeclined;

  /// Yolcunun kendi isteğini geri çektiği durum.
  ///
  /// In tr, this message translates to:
  /// **'Geri çekildi'**
  String get seatRequestWithdrawn;

  /// İstek sunucuya ulaşmadı veya sunucu reddetti. Hiçbir koltuk istenmedi.
  ///
  /// In tr, this message translates to:
  /// **'İstek gönderilemedi'**
  String get seatRequestFailed;

  /// Üye kendi yayımladığı yolculuğa istek gönderemez.
  ///
  /// In tr, this message translates to:
  /// **'Bu senin yolculuğun'**
  String get seatRequestOwnRoute;

  /// Sürücünün sunduğu koltukların hepsi kabul edilmiş durumda.
  ///
  /// In tr, this message translates to:
  /// **'Sunulan koltukların tamamı verilmiş'**
  String get seatRequestRouteFull;

  /// Yolculuk iptal edilmiş veya kalkışı geçmiş. Yeni bir istek kabul edilmez.
  ///
  /// In tr, this message translates to:
  /// **'Bu yolculuk artık geçerli değil'**
  String get seatRequestUnavailable;

  /// Tekrarlayan bir plan için hangi günün koltuğunun isteneceğini seçtiren sayfanın başlığı. Bir takvim değildir; sunucunun verdiği günler listelenir.
  ///
  /// In tr, this message translates to:
  /// **'Hangi gün?'**
  String get seatRequestChooseDayTitle;

  /// Seçim sayfasının açıklaması. Koltuğun boş olduğunu veya isteğin kabul edileceğini ima etmez.
  ///
  /// In tr, this message translates to:
  /// **'Bu plan birden çok gün çalışıyor. Koltuk istediğin günü seç.'**
  String get seatRequestChooseDayBody;

  /// Tekrarlayan bir planda gün seçme sayfasını açan düğme. İstek henüz gönderilmez.
  ///
  /// In tr, this message translates to:
  /// **'Gün seç'**
  String get seatRequestChooseDay;

  /// Sunucu bu rota için şu an istek gönderilebilecek hiçbir gün bildirmedi. Nedenini iddia etmez: dolu, iptal veya süresi doldu DEMEZ.
  ///
  /// In tr, this message translates to:
  /// **'Şu anda istenebilecek bir gün yok'**
  String get seatRequestNoDaysOffered;

  /// Sunucunun şu an sunduğu her gün için bu üyenin zaten bir isteği var. Her istek başına bir gün ömür boyu tek kezdir; sonucu ne olursa olsun aynı gün tekrar istenemez.
  ///
  /// In tr, this message translates to:
  /// **'Sunulan günlerin hepsi için istek gönderdin'**
  String get seatRequestEveryDayAsked;

  /// Üyenin gönderdiği koltuk isteklerinin listesi. Kendi geçmişidir.
  ///
  /// In tr, this message translates to:
  /// **'İsteklerim'**
  String get myRequestsTitle;

  /// Sıralama açıklaması. Sunucunun döndürdüğü sıradır; istemci sıralama yapmaz.
  ///
  /// In tr, this message translates to:
  /// **'En son gönderilenler önce'**
  String get myRequestsSubtitle;

  /// Sunucu başarıyla yanıt verdi ve hiç istek yok. Hata DEĞİLDİR.
  ///
  /// In tr, this message translates to:
  /// **'Henüz koltuk istemedin'**
  String get myRequestsEmpty;

  /// Boş durumun açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Bir yolculuk bulup koltuk istediğinde burada görünür.'**
  String get myRequestsEmptyBody;

  /// Bir sonraki sayfayı ister.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla göster'**
  String get myRequestsLoadMore;

  /// Sonraki sayfa gelmedi. Ekrandaki istekler yerinde kalır.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki istekler yüklenemedi'**
  String get myRequestsLoadMoreFailed;

  /// Yalnızca yanıtlanmamış bir istek geri çekilebilir.
  ///
  /// In tr, this message translates to:
  /// **'İsteği geri çek'**
  String get myRequestsWithdraw;

  /// Sunucu geri çekmeyi onayladıktan sonra gösterilen bilgi.
  ///
  /// In tr, this message translates to:
  /// **'İstek geri çekildi'**
  String get myRequestsWithdrawn;

  /// Sunucuya ulaşılamadı veya sunucu reddetti. İstek olduğu gibi kaldı.
  ///
  /// In tr, this message translates to:
  /// **'İstek geri çekilemedi'**
  String get myRequestsWithdrawFailed;

  /// Yolculuğun güncel durumu. İsteğin kendi durumundan ayrı bir gerçektir.
  ///
  /// In tr, this message translates to:
  /// **'Bu yolculuk iptal edildi'**
  String get myRequestsRouteCancelled;

  /// Yolculuğun kalkışı geçmiş. İsteğin kendi durumundan ayrı bir gerçektir.
  ///
  /// In tr, this message translates to:
  /// **'Bu yolculuk geçti'**
  String get myRequestsRouteDeparted;

  /// Profil ekranından İsteklerim listesine giden satır.
  ///
  /// In tr, this message translates to:
  /// **'İsteklerim'**
  String get myRequestsOpen;

  /// Bu yolculuğa gelen koltuk isteklerini açar.
  ///
  /// In tr, this message translates to:
  /// **'İstekler'**
  String get routeRequestsOpen;

  /// Düğmenin ekran okuyucu etiketi; birden çok kart aynı eylemi sunduğunda hangisini açtığını söyler.
  ///
  /// In tr, this message translates to:
  /// **'{journey} için gelen istekler'**
  String routeRequestsOpenSemanticLabel(String journey);

  /// Sürücünün yayımladığı bir yolculuğa gelen koltuk istekleri.
  ///
  /// In tr, this message translates to:
  /// **'Gelen istekler'**
  String get routeRequestsTitle;

  /// Sunucu başarıyla yanıt verdi ve hiç istek yok. Hata DEĞİLDİR.
  ///
  /// In tr, this message translates to:
  /// **'Bu yolculuk için henüz istek yok'**
  String get routeRequestsEmpty;

  /// Boş durumun açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Biri koltuk istediğinde burada görünür.'**
  String get routeRequestsEmptyBody;

  /// Bir sonraki sayfayı ister.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla göster'**
  String get routeRequestsLoadMore;

  /// Sonraki sayfa gelmedi. Ekrandaki istekler yerinde kalır.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki istekler yüklenemedi'**
  String get routeRequestsLoadMoreFailed;

  /// Sürücü koltuğu paylaşmayı kabul eder. Rezervasyon veya ödeme DEĞİLDİR.
  ///
  /// In tr, this message translates to:
  /// **'Kabul et'**
  String get routeRequestsAccept;

  /// Sürücü isteği reddeder. Koltuk sayısını değiştirmez.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get routeRequestsDecline;

  /// Kabul düğmesinin ekran okuyucu etiketi; hangi yolcuyu kabul ettiğini söyler.
  ///
  /// In tr, this message translates to:
  /// **'{passenger} isteğini kabul et'**
  String routeRequestsAcceptSemanticLabel(String passenger);

  /// Reddet düğmesinin ekran okuyucu etiketi.
  ///
  /// In tr, this message translates to:
  /// **'{passenger} isteğini reddet'**
  String routeRequestsDeclineSemanticLabel(String passenger);

  /// Sunucu kabulü onayladıktan sonra gösterilen bilgi.
  ///
  /// In tr, this message translates to:
  /// **'İstek kabul edildi'**
  String get routeRequestsAccepted;

  /// Sunucu reddi onayladıktan sonra gösterilen bilgi.
  ///
  /// In tr, this message translates to:
  /// **'İstek reddedildi'**
  String get routeRequestsDeclined;

  /// Sunucu kapasiteyi kendisi bilir; istemci koltuk saymaz. Bu, sunucunun verdiği yanıttır.
  ///
  /// In tr, this message translates to:
  /// **'Sunulan koltukların tamamı verilmiş'**
  String get routeRequestsFull;

  /// Yolculuk iptal edilmiş veya kalkışı geçmiş; yeni bir kabul yapılamaz.
  ///
  /// In tr, this message translates to:
  /// **'Bu yolculuk artık geçerli değil'**
  String get routeRequestsRouteUnavailable;

  /// Sunucuya ulaşılamadı veya sunucu reddetti. İstek olduğu gibi kaldı.
  ///
  /// In tr, this message translates to:
  /// **'İstek yanıtlanamadı'**
  String get routeRequestsDecisionFailed;

  /// Bir sonuç kartının ekran okuyucu için tek parça okunuşu.
  ///
  /// In tr, this message translates to:
  /// **'{driver}, {journey}, {departure}, {seats}'**
  String discoveryCardSemanticLabel(
    String driver,
    String journey,
    String departure,
    String seats,
  );

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

  /// Profil listesi satırı; üyenin kendisi hakkında aldığı geri bildirimleri açar. Üyenin yazdıkları değil — bu yüzden "Değerlendirmelerim" değil.
  ///
  /// In tr, this message translates to:
  /// **'Hakkımdaki değerlendirmeler'**
  String get profileMyReviews;

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

  /// 409 için son çare. Alan adı belirtmez: aynı kod yayınlama, koltuk isteği ve yolculuk komutlarından gelebilir. Sunucunun adlandırdığı ve bu sürümün tanıdığı her gerekçenin kendi metni vardır; buraya yalnızca gerekçesiz ya da tanınmayan bir 409 düşer. Sessizce yeni bir kimlikle tekrar denenmez.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem mevcut durum nedeniyle tamamlanamadı. Bilgileri yenileyip tekrar deneyin.'**
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

  /// Profil kurulum ekranı başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Sana nasıl hitap edelim?'**
  String get profileSetupTitle;

  /// Profil kurulum ekranı açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Bu ad, yolculuk paylaştığın kişilere görünür.'**
  String get profileSetupBody;

  /// Profil kurulumundaki ad alanının etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Adın'**
  String get profileSetupFieldLabel;

  /// Profil kurulumundaki ad alanının ipucu metni.
  ///
  /// In tr, this message translates to:
  /// **'Ayşe Demir'**
  String get profileSetupFieldHint;

  /// Profil kurulumunu tamamlayan buton.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get profileSetupSubmit;

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

  /// Profildeki ad düzenleme satırı ve ekran başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Adını düzenle'**
  String get profileEditName;

  /// Ad düzenleme ekranındaki kaydetme butonu.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get profileEditSave;

  /// Profil ekranında profil bulunamadığında görünen metin.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir adın yok.'**
  String get profileNoProfileYet;

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

  /// Sunucuda yolculuk kaydı yok. Tek kaynak: sürücünün rotaları, yolcunun istekleri ve yolculuk durumu ekranı aynı sözcüğü kullanır.
  ///
  /// In tr, this message translates to:
  /// **'Başlamadı'**
  String get tripStateNotStarted;

  /// Sürücü Başlat dedi ve sunucu kabul etti. Aracın hareket ettiğini, birinin bindiğini, alındığını veya bir konum bilindiğini SÖYLEMEZ.
  ///
  /// In tr, this message translates to:
  /// **'Başladı'**
  String get tripStateInProgress;

  /// Sürücü yolculuğun yapıldığını bildirdi.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get tripStateCompleted;

  /// Sürücü yolculuğun yapılmadığını bildirdi. Rota iptalinden ayrıdır.
  ///
  /// In tr, this message translates to:
  /// **'Yarıda bırakıldı'**
  String get tripStateAborted;

  /// Durumu, yanındaki istek ve rota durumlarından ayırt eden etiketli biçim.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuk: {state}'**
  String tripStateLine(String state);

  /// Yalnızca sunucunun bildirdiği durum başlamadı iken görünür. Başlatmaya izin olup olmadığına sunucu karar verir.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuğu başlat'**
  String get myRoutesStartTrip;

  /// Başlat düğmesinin hangi rotaya ait olduğunu söyler.
  ///
  /// In tr, this message translates to:
  /// **'{route} yolculuğunu başlat'**
  String myRoutesStartTripSemanticLabel(String route);

  /// Sunucu başlatmayı kabul ettikten SONRA gösterilir, öncesinde değil.
  ///
  /// In tr, this message translates to:
  /// **'{route} yolculuğu başladı.'**
  String myRoutesTripStarted(String route);

  /// Yalnızca sunucunun bildirdiği durum başladı iken görünür.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuğu tamamla'**
  String get myRoutesCompleteTrip;

  /// Tamamla düğmesinin hangi rotaya ait olduğunu söyler.
  ///
  /// In tr, this message translates to:
  /// **'{route} yolculuğunu tamamla'**
  String myRoutesCompleteTripSemanticLabel(String route);

  /// Yolculuğun yapılmadığını bildirir. Gerekçe sorulmaz ve saklanmaz: tanımlı bir gerekçe listesi yok.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuğu yarıda bırak'**
  String get myRoutesAbortTrip;

  /// Yarıda bırak düğmesinin hangi rotaya ait olduğunu söyler.
  ///
  /// In tr, this message translates to:
  /// **'{route} yolculuğunu yarıda bırak'**
  String myRoutesAbortTripSemanticLabel(String route);

  /// Sunucu kabul ettikten SONRA gösterilir, öncesinde değil.
  ///
  /// In tr, this message translates to:
  /// **'{route} yolculuğu tamamlandı.'**
  String myRoutesTripCompleted(String route);

  /// Sunucu kabul ettikten SONRA gösterilir, öncesinde değil.
  ///
  /// In tr, this message translates to:
  /// **'{route} yolculuğu yarıda bırakıldı.'**
  String myRoutesTripAborted(String route);

  /// Başlamamış bir yolculuk tamamlanamaz veya yarıda bırakılamaz.
  ///
  /// In tr, this message translates to:
  /// **'Bu yolculuk henüz başlatılmamış.'**
  String get myRoutesTripNotStarted;

  /// Kalkışa sunucu kendi saatiyle karar verir; cihaz saati burada hiç kullanılmaz.
  ///
  /// In tr, this message translates to:
  /// **'Bu yolculuk henüz başlatılamaz.'**
  String get myRoutesStartDepartureNotReached;

  /// Sunucu, bir planı gün belirtmeden başlatmayı reddeder: bir planın tek kalkışı yoktur. Phase 16b'den beri bu bir eksiklik değil; gün belirten komut vardır ve Yolculuklar bölümünden ulaşılır. Bu yüzden metin 'henüz yok' demez.
  ///
  /// In tr, this message translates to:
  /// **'Hangi günü kastettiğini seç ve yolculuğu oradan başlat.'**
  String get myRoutesStartRecurringUnsupported;

  /// Sunucu, o günün rota-yerel takvim günü geçtiği için başlatmayı reddetti. Yalnızca BU günü söyler: başka bir günün başlatılabileceğini iddia etmez, çünkü istemci bunu bilmez.
  ///
  /// In tr, this message translates to:
  /// **'O günün yolculuğu artık başlatılamaz.'**
  String get myRoutesStartServiceDatePassed;

  /// Rota yayından kalkmış.
  ///
  /// In tr, this message translates to:
  /// **'Bu rota artık başlatılamaz.'**
  String get myRoutesStartRouteUnavailable;

  /// Ekrandaki satır eskimiş; liste sunucudan yeniden okunur.
  ///
  /// In tr, this message translates to:
  /// **'Bu yolculuk zaten tamamlanmış.'**
  String get myRoutesTripAlreadyCompleted;

  /// Ekrandaki satır eskimiş; liste sunucudan yeniden okunur.
  ///
  /// In tr, this message translates to:
  /// **'Bu yolculuk zaten yarıda bırakılmış.'**
  String get myRoutesTripAlreadyAborted;

  /// Bir rota kartının ekran okuyucuya okunan tam hâli.
  ///
  /// In tr, this message translates to:
  /// **'{route}, {departure}, {seats}, {status}, {trip}'**
  String myRoutesCardSemanticLabel(
    String route,
    String departure,
    String seats,
    String status,
    String trip,
  );

  /// İptal düğmesinin hangi rotaya ait olduğunu söyler.
  ///
  /// In tr, this message translates to:
  /// **'{route} rotasını iptal et'**
  String myRoutesCancelSemanticLabel(String route);

  /// Tamamlanmış ve kabul edilmiş bir ilişki için değerlendirme kontrolünü açar. Yolculuğun fiziksel olarak yapıldığını KANITLAMAZ; sunucunun bildiği tek şey sürücünün tamamlandı demesidir.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuğu değerlendir'**
  String get reviewSubmit;

  /// Kontrolün hangi ilişkiye ait olduğunu söyler.
  ///
  /// In tr, this message translates to:
  /// **'{member} ile yaptığın yolculuğu değerlendir'**
  String reviewSubmitSemanticLabel(String member);

  /// Değerlendirme sayfasının başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Bu yolculuğu değerlendir'**
  String get reviewSheetTitle;

  /// Ne olduğunu ve ne OLMADIĞINI söyler: özel geri bildirim, herkese açık itibar değil.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirmen yalnızca değerlendirdiğin kişiye gösterilir; o da seni değerlendirdiğinde ya da süre dolduğunda. Puan ortalaması, sayısı veya herkese açık bir profil yok.'**
  String get reviewSheetBody;

  /// Her yıldızın ekran okuyucudaki adı.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{1 yıldız} other{{count} yıldız}}'**
  String reviewStarSemanticLabel(int count);

  /// Değerlendirmeyi gönderir. Puan seçilene kadar ve gönderim sürerken kapalıdır.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get reviewSend;

  /// Sayfayı kapatır. Cevabı bilinmeyen bir denemeyi iptal etmez.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get reviewDismiss;

  /// Üyenin kendi verdiği puan. Karşı tarafın ne yazdığı ya da yazıp yazmadığı asla gösterilmez.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirmen: {rating}/5'**
  String reviewSubmitted(int rating);

  /// Sunucu kabul ettikten SONRA gösterilir, öncesinde değil.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirmen kaydedildi.'**
  String get reviewSubmittedToast;

  /// Cevabı bilinmeyen bir denemeyi AYNI kimlik ve AYNI puanla tekrarlar. Puanı değiştirmek için önce denemeden vazgeçilmeli.
  ///
  /// In tr, this message translates to:
  /// **'Aynı değerlendirmeyi tekrar gönder'**
  String get reviewRetry;

  /// Cevabı bilinmeyen denemeyi bırakır. Sunucuya ilk deneme ulaşmışsa yeni gönderim doğru biçimde zaten değerlendirildi yanıtı alır.
  ///
  /// In tr, this message translates to:
  /// **'Bu denemeden vazgeç'**
  String get reviewAbandon;

  /// Ağ hatası: gidip gitmediği bilinmiyor, bu yüzden tekrar aynı kimlikle gider.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirmen gönderilemedi. Aynı puanla tekrar deneyebilirsin.'**
  String get reviewIndeterminate;

  /// Süreye sunucu karar verir; istemci hiçbir zaman hesaplamaz.
  ///
  /// In tr, this message translates to:
  /// **'Bu yolculuğun değerlendirme süresi doldu.'**
  String get reviewWindowClosed;

  /// Ekrandaki satır eskimiş; liste sunucudan yeniden okunur.
  ///
  /// In tr, this message translates to:
  /// **'Bu yolculuğu zaten değerlendirmişsin.'**
  String get reviewAlreadyReviewed;

  /// İstek kabul edilmemiş ya da yolculuk tamamlanmamış. Her ikisi de satırın eskidiğini söyler.
  ///
  /// In tr, this message translates to:
  /// **'Bu yolculuk artık değerlendirilemiyor.'**
  String get reviewNotEligible;

  /// Aynı kimlik başka bir değerlendirmeye ait. Sessizce yeni kimlik üretilmez.
  ///
  /// In tr, this message translates to:
  /// **'Bu değerlendirme gönderilemedi. Listeyi yenileyip tekrar dene.'**
  String get reviewIdConflict;

  /// Tek bir yolculuğun sunucudaki durumunu gösteren ekranın başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuk durumu'**
  String get tripStatusTitle;

  /// Sürücünün yayınladığı kalkış. Gerçekleşen bir saat değildir.
  ///
  /// In tr, this message translates to:
  /// **'Planlanan kalkış'**
  String get tripStatusDeparture;

  /// Yolculuğun sunucudaki durumunu etiketler. Ekran başlığından ayrıdır.
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get tripStatusState;

  /// Başladı durumunun ne DEMEDİĞİNİ açıkça söyler. Ürün konum, harita, navigasyon veya yolcu varlığı bilmiyor.
  ///
  /// In tr, this message translates to:
  /// **'Bu yalnızca yolculuğu RideMate\'te başlattığını gösterir. Konum, harita, navigasyon veya yolcu bilgisi tutulmaz.'**
  String get tripStatusStartedNote;

  /// Sunucunun kaydettiği an. Kalkış saati değildir, ve durum sözcüğünden ayrı yazılır: ikisi aynı ekranda yan yana durur.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get tripStatusStartedAt;

  /// Sunucunun kaydettiği an.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanma'**
  String get tripStatusCompletedAt;

  /// Sunucunun kaydettiği an.
  ///
  /// In tr, this message translates to:
  /// **'Yarıda bırakılma'**
  String get tripStatusAbortedAt;

  /// Bu yolculuğun hangi güne ait olduğunu etiketler. Plan tarihi değil, o günün kendisidir.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuk günü'**
  String get tripStatusServiceDate;

  /// Rota yüklenmiş sayfalarda bulunamadı. Uydurulmuş bir yolculuk gösterilmez.
  ///
  /// In tr, this message translates to:
  /// **'Bu rota listende yok'**
  String get tripStatusNotFound;

  /// Tek bir rotayı okuyan bir uç nokta yok; liste yeniden okunur.
  ///
  /// In tr, this message translates to:
  /// **'Rotalarını yeniden yükleyip tekrar dene.'**
  String get tripStatusNotFoundBody;

  /// Sürücünün bugün çalışan ve sürmekte olan yolculuklarını listeleyen bölümün başlığı. Rota planlarından ayrıdır: bir plan her çalıştığı gün için ayrı bir yolculuktur.
  ///
  /// In tr, this message translates to:
  /// **'Yolculuklar'**
  String get journeysSectionTitle;

  /// Bölümün neyi listelediğini söyler. Sunucunun kuralıdır; istemci gün hesaplamaz.
  ///
  /// In tr, this message translates to:
  /// **'Bugün çalışan yolculuklar ve başlattığın yolculuklar.'**
  String get journeysSectionBody;

  /// Sunucu bugün için yolculuk döndürmedi. Nedenini iddia etmez.
  ///
  /// In tr, this message translates to:
  /// **'Bugün çalışan bir yolculuk yok'**
  String get journeysEmpty;

  /// Boş durumun neden boş olabileceğini değil, bu listenin ne olduğunu açıklar.
  ///
  /// In tr, this message translates to:
  /// **'Rotalarından biri çalıştığı her gün burada bir yolculuk görünür.'**
  String get journeysEmptyBody;

  /// Yolculuk listesi okunamadı. Yolculuk olmadığı iddia edilmez.
  ///
  /// In tr, this message translates to:
  /// **'Yolculukların yüklenemedi.'**
  String get journeysFailed;

  /// Sunucu bu rota ve gün için bir yolculuk vermedi. Rota başkasının olabilir veya rota o gün çalışmıyor olabilir; ikisi kasten ayırt edilmez.
  ///
  /// In tr, this message translates to:
  /// **'Bu yolculuk okunamadı'**
  String get journeyNotFound;

  /// Okunamayan yolculuk için tek doğru öneri.
  ///
  /// In tr, this message translates to:
  /// **'Günü kontrol edip tekrar dene.'**
  String get journeyNotFoundBody;

  /// Bir yolculuk satırının ekran okuyucuda tek parça olarak okunması. Sıra veya renk değil, metin taşır.
  ///
  /// In tr, this message translates to:
  /// **'{route}, {date}, {departure}, {trip}'**
  String journeyCardSemanticLabel(
    String route,
    String date,
    String departure,
    String trip,
  );

  /// Yolculuk satırının açma eyleminin etiketi. Hangi gün olduğunu söyler; 'bugünkü' veya 'sıradaki' demez.
  ///
  /// In tr, this message translates to:
  /// **'{route} rotasının {date} günündeki yolculuğunu aç'**
  String journeyOpenSemanticLabel(String route, String date);

  /// Üyenin kendisi hakkında aldığı değerlendirmeleri gösteren ekranın başlığı. Bir itibar sayfası değildir: ortalama, toplam ya da herkese açık bir puan yoktur.
  ///
  /// In tr, this message translates to:
  /// **'Hakkındaki değerlendirmeler'**
  String get receivedReviewsTitle;

  /// Sunucunun döndürdüğü sıra, olduğu gibi söylenir. İstemci hiçbir şeyi sıralamaz.
  ///
  /// In tr, this message translates to:
  /// **'En son gönderilenler önce'**
  String get receivedReviewsSubtitle;

  /// Sunucu yanıt verdi ve yayımlanmış hiçbir değerlendirme döndürmedi. ASLA 'kimse seni değerlendirmedi' demez: yayımlanmamış değerlendirmeler olabilir ve istemcinin bunu bilmesine izin verilmez. Hata DEĞİLDİR.
  ///
  /// In tr, this message translates to:
  /// **'Görüntülenebilecek bir geri bildirim yok'**
  String get receivedReviewsEmpty;

  /// Yokluğu açıklamaya çalışmaz. Karşı tarafın ne yaptığına dair hiçbir iddia taşımaz.
  ///
  /// In tr, this message translates to:
  /// **'Yeni geri bildirimler burada görünür.'**
  String get receivedReviewsEmptyBody;

  /// Bir sonraki sayfayı ister. Sunucu imleç gönderdiği sürece görünür.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla göster'**
  String get receivedReviewsLoadMore;

  /// Sonraki sayfa gelmedi. Ekrandaki geri bildirimler yerinde kalır.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki geri bildirimler yüklenemedi'**
  String get receivedReviewsLoadMoreFailed;

  /// Değerlendirmeyi yazanın o yolculuktaki tarafı. Sunucunun gönderdiği role göre yazılır, ekrandan çıkarılmaz.
  ///
  /// In tr, this message translates to:
  /// **'Sürücü'**
  String get receivedReviewsRoleDriver;

  /// Değerlendirmeyi yazanın o yolculuktaki tarafı. Sunucunun gönderdiği role göre yazılır, ekrandan çıkarılmaz.
  ///
  /// In tr, this message translates to:
  /// **'Yolcu'**
  String get receivedReviewsRolePassenger;

  /// Tek bir değerlendirmenin puanı. Tam sayıdır: ondalık bir değer birden çok puanın ortalandığını ima ederdi.
  ///
  /// In tr, this message translates to:
  /// **'5 üzerinden {rating}'**
  String receivedReviewRatingSemanticLabel(int rating);

  /// Değerlendirmenin gönderildiği an. Ne zaman yayımlandığını ya da neden yayımlandığını söylemez.
  ///
  /// In tr, this message translates to:
  /// **'Gönderildi: {when}'**
  String receivedReviewSubmittedAt(String when);

  /// Bir geri bildirim kartının ekran okuyucuya okunan tam hâli. Yolculuk, oku görmeyen biri için de anlaşılır olsun diye buraya da yazılır.
  ///
  /// In tr, this message translates to:
  /// **'{member}, {role}. {rating}. {journey}, {departure}'**
  String receivedReviewCardSemanticLabel(
    String member,
    String role,
    String rating,
    String journey,
    String departure,
  );
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
