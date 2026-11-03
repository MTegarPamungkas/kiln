import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/deep_link/app_link_builder.dart';
import 'package:{{app_name}}/extensions/deep_link/deep_link_config.dart';

void main() {
  final builder = AppLinkBuilder(
    config: const DeepLinkConfig(
      scheme: 'kiln',
      allowedHosts: <String>['kiln.dev', 'app.kiln.dev'],
    ),
  );

  test('builds custom scheme links from the path', () {
    expect(builder.custom('/profile/42'), Uri.parse('kiln://profile/42'));
    expect(builder.custom('profile'), Uri.parse('kiln://profile'));
  });

  test('adds sorted query parameters', () {
    expect(
      builder.custom(
        '/profile/42',
        query: const <String, String>{'ref': 'share', 'from': 'email'},
      ),
      Uri.parse('kiln://profile/42?from=email&ref=share'),
    );
  });

  test('rejects an empty custom scheme path', () {
    expect(() => builder.custom('/'), throwsArgumentError);
    expect(() => builder.custom(''), throwsArgumentError);
  });

  test('builds universal links with the first allowed host', () {
    expect(
      builder.universal('/profile/42'),
      Uri.parse('https://kiln.dev/profile/42'),
    );
  });

  test('builds universal links with an explicit host and query', () {
    expect(
      builder.universal(
        'profile/42',
        host: 'App.Kiln.Dev',
        query: const <String, String>{'ref': 'share'},
      ),
      Uri.parse('https://app.kiln.dev/profile/42?ref=share'),
    );
  });

  test('requires a host when no allowed host is configured', () {
    final customOnly = AppLinkBuilder(
      config: const DeepLinkConfig(scheme: 'kiln'),
    );

    expect(() => customOnly.universal('/profile'), throwsStateError);
    expect(
      customOnly.universal('/profile', host: 'kiln.dev'),
      Uri.parse('https://kiln.dev/profile'),
    );
  });
}
