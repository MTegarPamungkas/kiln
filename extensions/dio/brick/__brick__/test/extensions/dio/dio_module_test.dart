import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/dio/dio_client.dart';
import 'package:{{app_name}}/extensions/dio/dio_config.dart';
import 'package:{{app_name}}/extensions/dio/dio_module.dart';
import 'package:{{app_name}}/extensions/dio/dio_support.dart';

void main() {
  test('registers the HTTP contracts and default interceptors', () {
    final registry = createTestRegistry();
    registry.unregister<HttpClient>();

    const DioModule().register(registry);

    expect(registry.read<HttpClient>(), isA<DioClient>());
    expect(registry.read<HttpPipeline>(), isA<HttpPipeline>());
    expect(registry.read<DioConfig>().baseUrl, isNotEmpty);
    expect(registry.read<DioSupport>(), isA<DioSupport>());

    final slot = registry.read<SlotRegistry>().find<HttpMiddleware>(
      SlotNames.httpInterceptors,
    );
    expect(slot, isNotNull);
    expect(slot!.items, hasLength(2));
  });
}
