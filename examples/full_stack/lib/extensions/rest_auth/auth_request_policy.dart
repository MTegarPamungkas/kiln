import 'package:kiln_core/kiln_core.dart';

import 'rest_auth_config.dart';

/// Shared origin and endpoint policy for bearer injection and 401 recovery.
final class AuthRequestPolicy {
  const AuthRequestPolicy(this.config);

  final RestAuthConfig config;

  HttpRequest resolve(HttpRequest request) =>
      request.copyWith(uri: config.endpoint(request.uri.toString()));

  bool isBackend(Uri uri) {
    final base = Uri.tryParse(config.baseUrl);
    return base != null &&
        base.host.isNotEmpty &&
        (base.isScheme('http') || base.isScheme('https')) &&
        uri.scheme == base.scheme &&
        uri.host == base.host &&
        uri.port == base.port;
  }

  bool isInternal(Uri uri) =>
      <String>[
            config.loginPath,
            config.registerPath,
            config.refreshPath,
            config.logoutPath,
          ]
          .where((path) => path.isNotEmpty)
          .any(
            (path) =>
                config.endpoint(path).normalizePath().path ==
                uri.normalizePath().path,
          );

  bool allows(HttpRequest request) =>
      isBackend(request.uri) && !isInternal(request.uri);
}
