// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kiln App';

  @override
  String get readyTitle => 'App ready';

  @override
  String get readyBody =>
      'The Kiln shell is running. Start building features in lib/features.';

  @override
  String get starterHint =>
      'Add extensions with kiln add, then run kiln doctor.';

  @override
  String get errorTitle => 'The app failed to start';

  @override
  String get errorBody =>
      'Check the project configuration, then restart the app.';

  @override
  String get failureTitle => 'Something went wrong';

  @override
  String get failureBody =>
      'Please try again. Contact support if the problem continues.';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionOk => 'OK';

  @override
  String get actionSave => 'Save';

  @override
  String get actionClose => 'Close';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageFollowSystem => 'Follow system';

  @override
  String get languageName => 'English';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String helloName(String name) {
    return 'Hello, $name!';
  }

  @override
  String get failureNetwork =>
      'There was a network problem. Check your connection and try again.';

  @override
  String get failureNetworkOffline =>
      'No internet connection. Check your network and try again.';

  @override
  String get failureAuth =>
      'Your session or credentials are invalid. Sign in again to continue.';

  @override
  String get failureAuthExpired => 'Your session expired. Sign in again.';

  @override
  String get failureAuthEmail => 'Verify your email address first.';

  @override
  String get failurePermission =>
      'Permission is required to continue. Open the app settings.';

  @override
  String get failurePermissionPermanently =>
      'Permission is blocked. Enable it in the app settings.';

  @override
  String get failureValidation =>
      'The information you entered is not valid yet.';

  @override
  String get failureConfiguration =>
      'The application configuration is incomplete.';

  @override
  String get failureStorage => 'Data could not be saved or read. Try again.';

  @override
  String get failureSecureStorage =>
      'Secure storage is not available on this device.';

  @override
  String get failureDatabase => 'The local database is unavailable. Try again.';

  @override
  String get failureRemoteDatabase =>
      'The data server cannot be reached. Try again.';

  @override
  String get failureFile => 'The file could not be processed. Try again.';

  @override
  String get failureNotifications =>
      'Notifications are unavailable. Check the notification permission.';

  @override
  String get failureDeepLink => 'The link is invalid or cannot be opened.';

  @override
  String get failureMedia => 'The media could not be opened or captured.';

  @override
  String get failureCache => 'The cache is unavailable. Data will be reloaded.';

  @override
  String get failureSession => 'Your session expired. Sign in again.';

  @override
  String get failureCancelled => 'The action was cancelled.';

  @override
  String get failureUnavailable => 'This feature is not available yet.';

  @override
  String get failureUnsupported =>
      'This feature is not supported on this device.';

  @override
  String get failureUnexpected => 'An unexpected error occurred. Try again.';
}
