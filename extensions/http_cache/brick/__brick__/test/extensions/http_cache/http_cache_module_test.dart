import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/http_cache/http_cache_module.dart';

void main() {
  test('module registers the cache and middleware', () {
    final registry = GetItRegistry()
      ..registerSingleton<SlotRegistry>(SlotRegistry())
      ..registerSingleton<HttpPipeline>(HttpPipeline());

    const HttpCacheModule().register(registry);

    expect(registry.read<HttpCache>(), isA<HttpCache>());
    expect(registry.read<HttpPipeline>().middleware, hasLength(1));
  });
}
