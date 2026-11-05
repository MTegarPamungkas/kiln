import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/http_cache/cache_settings.dart';
import 'package:{{app_name}}/extensions/http_cache/http_cache_support.dart';

void main() {
  test('reports memory backend without storage', () {
    const support = HttpCacheSupport(settings: HttpCacheSettings.defaults);

    final info = support.info;

    expect(info.isSupported, isTrue);
    expect(info.details['backend'], 'memory');
    expect(info.details['max_entries'], 100);
  });

  test('rejects a zero max entry count', () {
    const support = HttpCacheSupport(
      settings: HttpCacheSettings(maxEntries: 0),
    );

    expect(support.info.state, SupportState.notConfigured);
    expect(support.info.toFailure().kind, FailureKind.configuration);
  });

  test('rejects a negative TTL', () {
    const support = HttpCacheSupport(
      settings: HttpCacheSettings(defaultTtl: Duration(seconds: -1)),
    );

    expect(support.info.isSupported, isFalse);
  });

  test('rejects an empty cacheable status set', () {
    const support = HttpCacheSupport(
      settings: HttpCacheSettings(cacheableStatusCodes: <int>{}),
    );

    expect(support.info.isSupported, isFalse);
  });
}
