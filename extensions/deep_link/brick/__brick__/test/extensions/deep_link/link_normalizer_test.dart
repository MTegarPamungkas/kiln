import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/deep_link/deep_link_config.dart';
import 'package:{{app_name}}/extensions/deep_link/link_normalizer.dart';

void main() {
  final normalizer = LinkNormalizer();

  test('lowercases the scheme and host and strips the default port', () {
    final normalized = normalizer.normalize(
      Uri.parse('HTTPS://Kiln.Dev:443/Profile/42'),
    );

    expect(normalized, Uri.parse('https://kiln.dev/Profile/42'));
  });

  test('removes tracking query parameters and keeps the rest', () {
    final normalized = normalizer.normalize(
      Uri.parse(
        'https://kiln.dev/profile?utm_source=share&ref=home&FBClid=abc',
      ),
    );

    expect(normalized.queryParameters, <String, String>{'ref': 'home'});
  });

  test('collapses duplicate slashes and trailing slashes in the path', () {
    final normalized = normalizer.normalize(
      Uri.parse('https://kiln.dev//profile///42/'),
    );

    expect(normalized.path, '/profile/42');
  });

  test('drops the fragment', () {
    final normalized = normalizer.normalize(
      Uri.parse('https://kiln.dev/profile#section'),
    );

    expect(normalized.hasFragment, isFalse);
  });

  test('keeps tracking parameters and fragments when configured', () {
    final relaxed = LinkNormalizer(
      config: const DeepLinkConfig(
        stripTrackingParameters: false,
        dropFragment: false,
      ),
    );

    final normalized = relaxed.normalize(
      Uri.parse('https://kiln.dev/profile?utm_source=share#section'),
    );

    expect(normalized.queryParameters, <String, String>{
      'utm_source': 'share',
    });
    expect(normalized.fragment, 'section');
  });

  test('normalizes custom scheme links', () {
    final normalized = normalizer.normalize(
      Uri.parse('kiln://Profile/42/?utm_campaign=launch'),
    );

    expect(normalized, Uri.parse('kiln://profile/42'));
  });
}
