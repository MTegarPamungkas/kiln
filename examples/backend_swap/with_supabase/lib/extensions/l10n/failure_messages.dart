import 'dart:ui' show Locale;

import 'package:with_supabase/core/error/failure_presenter.dart';
import 'package:kiln_core/kiln_core.dart';

import '../../l10n/generated/app_localizations.dart';
import 'l10n_config.dart';

/// Localized [FailureMessages] backed by generated ARB translations.
final class L10nFailureMessages implements FailureMessages {
  const L10nFailureMessages({
    this.config = L10nConfig.defaults,
    this.resolveLocale,
  });

  final L10nConfig config;

  /// Live locale resolver, usually connected to [LocaleController.locale].
  final Locale? Function()? resolveLocale;

  AppLocalizations get _localizations {
    final requested = resolveLocale?.call();
    return lookupAppLocalizations(config.resolve(requested));
  }

  @override
  String messageFor(Failure failure) {
    final l10n = _localizations;
    return switch (failure.code.value) {
      'network.timeout' => l10n.failureNetwork,
      'network.offline' || 'network.unreachable' => l10n.failureNetworkOffline,
      'network.server' ||
      'network.retry_exhausted' ||
      'network.unknown' => l10n.failureNetwork,
      'auth.invalid_credentials' ||
      'auth.unauthorized' ||
      'auth.provider_disabled' => l10n.failureAuth,
      'auth.session_expired' => l10n.failureAuthExpired,
      'auth.email_not_verified' => l10n.failureAuthEmail,
      'auth.cancelled' ||
      'media.cancelled' ||
      'cancelled' => l10n.failureCancelled,
      'permission.denied' ||
      'permission.restricted' ||
      'media.permission_denied' => l10n.failurePermission,
      'permission.permanently_denied' => l10n.failurePermissionPermanently,
      'validation.invalid_input' ||
      'validation.unsupported_value' => l10n.failureValidation,
      'configuration.missing' ||
      'configuration.invalid' => l10n.failureConfiguration,
      'storage.read_failed' ||
      'storage.write_failed' ||
      'storage.not_found' => l10n.failureStorage,
      'secure_storage.unavailable' ||
      'secure_storage.read_failed' ||
      'secure_storage.write_failed' => l10n.failureSecureStorage,
      'database.not_found' ||
      'database.conflict' ||
      'database.unavailable' ||
      'database.query_failed' => l10n.failureDatabase,
      'remote_database.not_found' ||
      'remote_database.conflict' ||
      'remote_database.unavailable' ||
      'remote_database.query_failed' => l10n.failureRemoteDatabase,
      'file.not_found' ||
      'file.upload_failed' ||
      'file.download_failed' ||
      'file.delete_failed' => l10n.failureFile,
      'notifications.permission_denied' ||
      'notifications.unavailable' => l10n.failureNotifications,
      'deep_link.invalid' || 'deep_link.unavailable' => l10n.failureDeepLink,
      'media.unavailable' || 'media.invalid' => l10n.failureMedia,
      'cache.unavailable' || 'cache.invalid_entry' => l10n.failureCache,
      'session.expired' => l10n.failureSession,
      'support.unsupported_platform' ||
      'support.unsupported_device' => l10n.failureUnsupported,
      'unavailable' => l10n.failureUnavailable,
      _ => l10n.failureUnexpected,
    };
  }
}
