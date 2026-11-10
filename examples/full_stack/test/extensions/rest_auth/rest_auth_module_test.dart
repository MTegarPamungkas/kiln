import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:full_stack/extensions/rest_auth/rest_auth.dart';
import 'package:full_stack/extensions/rest_auth/rest_auth_config.dart';
import 'package:full_stack/extensions/rest_auth/rest_auth_module.dart';
import 'package:full_stack/extensions/rest_auth/rest_auth_support.dart';

import 'test_support.dart';

void main() {
  test('module registers auth, token provider, account, and middleware', () {
    final registry = GetItRegistry()
      ..registerSingleton<HttpClient>(FakeHttpClient(onRequest: authServer))
      ..registerSingleton<SecureStorage>(InMemorySecureStorage())
      ..registerSingleton<SessionController>(SessionController())
      ..registerSingleton<HttpPipeline>(HttpPipeline());

    const RestAuthModule().register(registry);

    expect(registry.read<AuthRepository>(), isA<RestAuth>());
    expect(registry.read<RestAuthConfig>(), isA<RestAuthConfig>());
    expect(registry.read<RestAuthSupport>(), isA<RestAuthSupport>());
    expect(registry.read<TokenProvider>(), isA<TokenProvider>());
    expect(registry.read<AccountManagement>(), isA<AccountManagement>());
    expect(registry.read<HttpPipeline>().middleware, hasLength(2));
  });

  test('module works without an HTTP pipeline', () {
    final registry = GetItRegistry()
      ..registerSingleton<HttpClient>(FakeHttpClient())
      ..registerSingleton<SecureStorage>(InMemorySecureStorage())
      ..registerSingleton<SessionController>(SessionController());

    const RestAuthModule().register(registry);

    expect(registry.read<AuthRepository>(), isA<RestAuth>());
    expect(registry.readOrNull<HttpPipeline>(), isNull);
  });
}
