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
