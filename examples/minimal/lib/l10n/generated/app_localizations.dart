import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Kiln App'**
  String get appTitle;

  /// No description provided for @readyTitle.
  ///
  /// In en, this message translates to:
  /// **'App ready'**
  String get readyTitle;

  /// No description provided for @readyBody.
  ///
  /// In en, this message translates to:
  /// **'The Kiln shell is running. Start building features in lib/features.'**
  String get readyBody;

  /// No description provided for @starterHint.
  ///
  /// In en, this message translates to:
  /// **'Add extensions with kiln add, then run kiln doctor.'**
  String get starterHint;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'The app failed to start'**
  String get errorTitle;

  /// No description provided for @errorBody.
  ///
  /// In en, this message translates to:
  /// **'Check the project configuration, then restart the app.'**
  String get errorBody;

  /// No description provided for @failureTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get failureTitle;

  /// No description provided for @failureBody.
  ///
  /// In en, this message translates to:
  /// **'Please try again. Contact support if the problem continues.'**
  String get failureBody;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionRetry;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageFollowSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageFollowSystem;

  /// No description provided for @languageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// Number of items in a list
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} =1{1 item} other{{count} items}}'**
  String itemsCount(int count);

  /// Greeting with the user's name
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String helloName(String name);

  /// No description provided for @failureNetwork.
  ///
  /// In en, this message translates to:
  /// **'There was a network problem. Check your connection and try again.'**
  String get failureNetwork;

  /// No description provided for @failureNetworkOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get failureNetworkOffline;

  /// No description provided for @failureAuth.
  ///
  /// In en, this message translates to:
  /// **'Your session or credentials are invalid. Sign in again to continue.'**
  String get failureAuth;

  /// No description provided for @failureAuthExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Sign in again.'**
  String get failureAuthExpired;

  /// No description provided for @failureAuthEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your email address first.'**
  String get failureAuthEmail;

  /// No description provided for @failurePermission.
  ///
  /// In en, this message translates to:
  /// **'Permission is required to continue. Open the app settings.'**
  String get failurePermission;

  /// No description provided for @failurePermissionPermanently.
  ///
  /// In en, this message translates to:
  /// **'Permission is blocked. Enable it in the app settings.'**
  String get failurePermissionPermanently;

  /// No description provided for @failureValidation.
  ///
  /// In en, this message translates to:
  /// **'The information you entered is not valid yet.'**
  String get failureValidation;

  /// No description provided for @failureConfiguration.
  ///
  /// In en, this message translates to:
  /// **'The application configuration is incomplete.'**
  String get failureConfiguration;

  /// No description provided for @failureStorage.
  ///
  /// In en, this message translates to:
  /// **'Data could not be saved or read. Try again.'**
  String get failureStorage;

  /// No description provided for @failureSecureStorage.
  ///
  /// In en, this message translates to:
  /// **'Secure storage is not available on this device.'**
  String get failureSecureStorage;

  /// No description provided for @failureDatabase.
  ///
  /// In en, this message translates to:
  /// **'The local database is unavailable. Try again.'**
  String get failureDatabase;

  /// No description provided for @failureRemoteDatabase.
  ///
  /// In en, this message translates to:
  /// **'The data server cannot be reached. Try again.'**
  String get failureRemoteDatabase;

  /// No description provided for @failureFile.
  ///
  /// In en, this message translates to:
  /// **'The file could not be processed. Try again.'**
  String get failureFile;

  /// No description provided for @failureNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications are unavailable. Check the notification permission.'**
  String get failureNotifications;

  /// No description provided for @failureDeepLink.
  ///
  /// In en, this message translates to:
  /// **'The link is invalid or cannot be opened.'**
  String get failureDeepLink;

  /// No description provided for @failureMedia.
  ///
  /// In en, this message translates to:
  /// **'The media could not be opened or captured.'**
  String get failureMedia;

  /// No description provided for @failureCache.
  ///
  /// In en, this message translates to:
  /// **'The cache is unavailable. Data will be reloaded.'**
  String get failureCache;

  /// No description provided for @failureSession.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Sign in again.'**
  String get failureSession;

  /// No description provided for @failureCancelled.
  ///
  /// In en, this message translates to:
  /// **'The action was cancelled.'**
  String get failureCancelled;

  /// No description provided for @failureUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This feature is not available yet.'**
  String get failureUnavailable;

  /// No description provided for @failureUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This feature is not supported on this device.'**
  String get failureUnsupported;

  /// No description provided for @failureUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Try again.'**
  String get failureUnexpected;
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
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
