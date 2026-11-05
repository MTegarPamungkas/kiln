import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'analytics brick renders the expected files',
    () async {
      final harness = ExtensionTestHarness(extensionRoot: Directory.current);

      final files = await harness.render(project: const {'name': 'analytics_app'});
      final paths = files.map((file) => file.relativePath).toList();

      expect(
        paths,
        containsAll(<String>[
          'lib/extensions/analytics/analytics_module.dart',
          'lib/extensions/analytics/posthog_analytics.dart',
          'lib/extensions/analytics/analytics_gateway.dart',
          'lib/extensions/analytics/sdk_posthog_gateway.dart',
          'lib/extensions/analytics/analytics_failure_mapper.dart',
          'lib/extensions/analytics/analytics_config.dart',
          'lib/extensions/analytics/analytics_event.dart',
          'lib/extensions/analytics/property_sanitizer.dart',
          'lib/extensions/analytics/consent_gate_analytics.dart',
          'lib/extensions/analytics/pii_scrubbing_analytics.dart',
          'lib/extensions/analytics/noop_analytics.dart',
          'lib/extensions/analytics/session_identity_listener.dart',
          'test/extensions/analytics/analytics_test.dart',
          'test/extensions/analytics/analytics_failure_mapper_test.dart',
          'test/extensions/analytics/analytics_module_test.dart',
          'test/extensions/analytics/analytics_config_test.dart',
          'test/extensions/analytics/analytics_event_test.dart',
          'test/extensions/analytics/property_sanitizer_test.dart',
          'test/extensions/analytics/consent_gate_analytics_test.dart',
          'test/extensions/analytics/pii_scrubbing_analytics_test.dart',
          'test/extensions/analytics/noop_analytics_test.dart',
          'test/extensions/analytics/session_identity_listener_test.dart',
          'test/extensions/analytics/analytics_contract_test.dart',
          'test/extensions/analytics/test_support.dart',
        ]),
      );

      final config = files.firstWhere(
        (file) => file.relativePath.endsWith('analytics_config.dart'),
      );
      final source = String.fromCharCodes(config.bytes);
      expect(source, contains("apiKey = ''"));
      expect(source, contains("host = 'https://us.i.posthog.com'"));
      expect(source, contains('flushInterval = const Duration(seconds: 30)'));

      final golden = File(
        p.join(
          Directory.current.path,
          'test',
          'goldens',
          'rendered',
          'lib',
          'extensions',
          'analytics',
          'analytics_config.dart.golden',
        ),
      );
      if (Platform.environment['UPDATE_GOLDENS'] == '1') {
        await golden.parent.create(recursive: true);
        await golden.writeAsString(source);
      }
      expect(source, golden.readAsStringSync());
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
