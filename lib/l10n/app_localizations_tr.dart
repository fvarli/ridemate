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
