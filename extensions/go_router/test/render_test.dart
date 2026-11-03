import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('go_router brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(
      project: const <String, Object?>{'name': 'nav_app'},
    );

    expect(const ManifestValidator().validate(harness.loadManifest()), isEmpty);
    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/go_router/go_router_module.dart',
        'lib/extensions/go_router/app_router.dart',
        'lib/extensions/go_router/app_routes.dart',
        'lib/extensions/go_router/router_config.dart',
        'lib/extensions/go_router/route_slot.dart',
        'lib/extensions/go_router/route_guard.dart',
        'lib/extensions/go_router/auth_redirect.dart',
        'lib/extensions/go_router/session_refresh_listenable.dart',
        'lib/extensions/go_router/deep_link_route_mapper.dart',
        'lib/extensions/go_router/notification_route_mapper.dart',
        'lib/extensions/go_router/navigation_observer.dart',
        'lib/extensions/go_router/not_found_page.dart',
        'lib/extensions/go_router/shell_scaffold.dart',
        'lib/extensions/go_router/route_transitions.dart',
        'test/extensions/go_router/app_router_test.dart',
        'test/extensions/go_router/go_router_module_test.dart',
        'test/extensions/go_router/app_routes_test.dart',
        'test/extensions/go_router/route_slot_test.dart',
        'test/extensions/go_router/route_guard_test.dart',
        'test/extensions/go_router/auth_redirect_test.dart',
        'test/extensions/go_router/session_refresh_listenable_test.dart',
        'test/extensions/go_router/deep_link_route_mapper_test.dart',
        'test/extensions/go_router/notification_route_mapper_test.dart',
        'test/extensions/go_router/navigation_observer_test.dart',
        'test/extensions/go_router/not_found_page_test.dart',
        'test/extensions/go_router/shell_scaffold_test.dart',
        'test/extensions/go_router/test_support.dart',
      ]),
    );

    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('router_config.dart'),
    );
    final source = String.fromCharCodes(config.bytes);
    expect(source, contains('initialLocation = AppRoutes.home'));
    expect(source, contains('debugLogDiagnostics = false'));

    final module = files.firstWhere(
      (file) => file.relativePath.endsWith('go_router_module.dart'),
    );
    final moduleSource = String.fromCharCodes(module.bytes);
    expect(moduleSource, contains("id => 'go_router'"));
    expect(moduleSource, contains('registry.readOrNull<SlotRegistry>()'));
  });
}
