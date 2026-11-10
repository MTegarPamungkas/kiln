import 'package:kiln_core/kiln_core.dart';

/// REST auth settings from the install prompts.
final class RestAuthConfig {
  const RestAuthConfig({
    this.baseUrl = '',
    this.loginPath = '/auth/login',
    this.registerPath = '/auth/register',
    this.refreshPath = '/auth/refresh',
    this.logoutPath = '/auth/logout',
    this.mePath = '/auth/me',
    this.forgotPasswordPath = '',
    this.verifyEmailPath = '',
    this.refreshLeeway = const Duration(seconds: 30),
  });

  static const defaults = RestAuthConfig(
    baseUrl: '{{{base_url}}}',
    loginPath: '{{{login_path}}}',
    registerPath: '{{{register_path}}}',
    refreshPath: '{{{refresh_path}}}',
    logoutPath: '{{{logout_path}}}',
    mePath: '{{{me_path}}}',
  );

  final String baseUrl;
  final String loginPath;
  final String registerPath;
  final String refreshPath;
  final String logoutPath;
  final String mePath;
  final String forgotPasswordPath;
  final String verifyEmailPath;
  final Duration refreshLeeway;

  Uri endpoint(String path) {
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final uri = Uri.parse(path);
    if (uri.hasScheme || uri.hasAuthority) {
      return Uri.parse(base).resolveUri(uri);
    }
    final relative = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse(base).resolve(relative);
  }

  /// Returns null when valid, or a configuration [Failure] otherwise.
  Failure? validate() {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      return const Failure(
        code: FailureCode.configurationMissing,
        message: 'The REST auth base URL is required.',
        kind: FailureKind.configuration,
      );
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        uri.host.isEmpty ||
        !(uri.isScheme('http') || uri.isScheme('https'))) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message: 'The REST auth base URL must be an absolute HTTP or HTTPS URL.',
        kind: FailureKind.configuration,
      );
    }
    for (final path in <String>[
      loginPath,
      registerPath,
      refreshPath,
      logoutPath,
      mePath,
    ]) {
      if (path.trim().isEmpty) {
        return const Failure(
          code: FailureCode.configurationMissing,
          message: 'REST auth endpoint paths cannot be empty.',
          kind: FailureKind.configuration,
        );
      }
    }
    if (refreshLeeway.isNegative) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message: 'REST auth refreshLeeway cannot be negative.',
        kind: FailureKind.configuration,
      );
    }
    return null;
  }
}
