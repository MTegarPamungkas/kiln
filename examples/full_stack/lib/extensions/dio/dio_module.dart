import 'package:kiln_core/kiln_core.dart';

import 'dio_client.dart';
import 'dio_config.dart';
import 'dio_support.dart';
import 'interceptors/interceptor_slot.dart';
import 'interceptors/request_id_interceptor.dart';
import 'interceptors/user_agent_interceptor.dart';

/// Registers the HTTP client, pipeline, and default interceptors.
final class DioModule extends KilnModule {
  const DioModule();

  @override
  String get id => 'dio';

  @override
  Set<String> get provides => const <String>{'http_client', 'http_pipeline'};

  @override
  void register(Registry registry) {
    const config = DioConfig.defaults;
    final slot = httpInterceptorSlot(registry);
    slot
      ..add(const RequestIdInterceptor(), priority: 5, owner: 'dio')
      ..add(const UserAgentInterceptor(), priority: 6, owner: 'dio');

    final pipeline = HttpPipeline();
    for (final entry in slot.entries) {
      pipeline.use(entry.item, priority: entry.priority);
    }
    final client = DioClient(config: config, pipeline: pipeline);
    final support = DioSupport(config: config);

    registry.registerSingleton<DioConfig>(config);
    registry.registerSingleton<DioSupport>(support);
    registry.registerSingleton<HttpPipeline>(pipeline);
    registry.registerSingleton<HttpClient>(client);
  }

  @override
  SupportInfo support(Registry registry) {
    return registry.read<DioSupport>().info;
  }
}
