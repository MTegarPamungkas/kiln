import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/http_retry/http_retry_module.dart';

void main() {
  test('module adds the retry middleware to the pipeline', () {
    final registry = GetItRegistry()
      ..registerSingleton<SlotRegistry>(SlotRegistry())
      ..registerSingleton<HttpPipeline>(HttpPipeline());

    const HttpRetryModule().register(registry);

    expect(registry.read<HttpPipeline>().middleware, hasLength(1));
  });
}
