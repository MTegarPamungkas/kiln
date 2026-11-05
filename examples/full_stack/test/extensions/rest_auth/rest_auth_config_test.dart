import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/extensions/rest_auth/rest_auth_config.dart';

void main() {
  test('defaults carry the rendered endpoints', () {
    const config = RestAuthConfig.defaults;

    expect(config.baseUrl, 'https://api.example.com');
    expect(config.loginPath, '/auth/login');
    expect(config.registerPath, '/auth/register');
    expect(config.refreshPath, '/auth/refresh');
    expect(config.logoutPath, '/auth/logout');
    expect(config.mePath, '/auth/me');
  });

  test('endpoint joins slash variants', () {
    const config = RestAuthConfig(baseUrl: 'https://api.kiln.dev/v1');

    expect(
      config.endpoint('/auth/login').toString(),
      'https://api.kiln.dev/v1/auth/login',
    );
  });
}
