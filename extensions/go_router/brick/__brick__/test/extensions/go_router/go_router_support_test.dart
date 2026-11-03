import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/go_router/go_router_support.dart';
import 'package:{{app_name}}/extensions/go_router/router_config.dart';

void main() {
  test('reports the initial location, route count, and switches', () {
    const support = GoRouterSupport(
      config: AppRouterConfig(
        initialLocation: '/home',
        enableAuthRedirect: true,
      ),
      routeCount: 4,
    );

    final info = support.info;

    expect(info.isSupported, isTrue);
    expect(info.details['initial_location'], '/home');
    expect(info.details['routes'], 4);
    expect(info.details['auth_redirect'], isTrue);
  });

  test('rejects an initial location without a leading slash', () {
    const support = GoRouterSupport(
      config: AppRouterConfig(initialLocation: 'home'),
      routeCount: 1,
    );

    final info = support.info;

    expect(info.state, SupportState.notConfigured);
    expect(info.toFailure().code, FailureCode.configurationMissing);
  });

  test('rejects an empty initial location', () {
    const support = GoRouterSupport(
      config: AppRouterConfig(initialLocation: ''),
      routeCount: 0,
    );

    expect(support.info.isSupported, isFalse);
  });
}
