import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/rest_auth/rest_auth_config.dart';

void main() {
  test('defaults carry the rendered endpoints', () {
    const config = RestAuthConfig.defaults;

    expect(config.baseUrl, '{{{base_url}}}');
    expect(config.loginPath, '{{{login_path}}}');
    expect(config.registerPath, '{{{register_path}}}');
    expect(config.refreshPath, '{{{refresh_path}}}');
    expect(config.logoutPath, '{{{logout_path}}}');
    expect(config.mePath, '{{{me_path}}}');
  });

  test('endpoint joins slash variants', () {
    const config = RestAuthConfig(baseUrl: 'https://api.kiln.dev/v1');

    expect(
      config.endpoint('/auth/login').toString(),
      'https://api.kiln.dev/v1/auth/login',
    );
  });
}
