import 'package:kiln_core/kiln_core.dart';

import 'router_config.dart';

/// Reports the router configuration and the registered route count.
final class GoRouterSupport {
  const GoRouterSupport({required this.config, required this.routeCount});

  final AppRouterConfig config;
  final int routeCount;

  SupportInfo get info {
    final location = config.initialLocation;
    if (location.isEmpty || !location.startsWith('/')) {
      return SupportInfo.unsupported(
        SupportState.notConfigured,
        message: 'Router initialLocation must start with "/".',
        details: <String, Object?>{'initial_location': location},
      );
    }
    return SupportInfo.supported(
      details: <String, Object?>{
        'initial_location': location,
        'routes': routeCount,
        'auth_redirect': config.enableAuthRedirect,
      },
    );
  }
}
