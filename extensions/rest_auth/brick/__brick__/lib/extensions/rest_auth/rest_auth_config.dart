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
    final relative = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse(base).resolve(relative);
  }
}
