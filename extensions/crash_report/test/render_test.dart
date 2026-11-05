import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'crash_report brick renders the expected files',
    () async {
      final harness = ExtensionTestHarness(extensionRoot: Directory.current);

      final files = await harness.render(
        project: const {'name': 'crash_report_app'},
      );
      final paths = files.map((file) => file.relativePath).toList();

      expect(
        paths,
        containsAll(<String>[
          'lib/extensions/crash_report/crash_report_module.dart',
          'lib/extensions/crash_report/crash_report_config.dart',
          'lib/extensions/crash_report/crash_report_gateway.dart',
          'lib/extensions/crash_report/sentry_crash_gateway.dart',
          'lib/extensions/crash_report/sentry_crash_reporter.dart',
          'lib/extensions/crash_report/noop_crash_reporter.dart',
          'lib/extensions/crash_report/consent_gate_crash_reporter.dart',
          'lib/extensions/crash_report/pii_scrubbing_crash_reporter.dart',
          'lib/extensions/crash_report/safe_crash_reporter.dart',
          'lib/extensions/crash_report/crash_report_failure_mapper.dart',
          'lib/extensions/crash_report/crash_report_support.dart',
          'lib/extensions/crash_report/gate_crash_report.dart',
          'test/extensions/crash_report/test_support.dart',
          'test/extensions/crash_report/crash_reporter_contract_test.dart',
          'test/extensions/crash_report/sentry_crash_reporter_test.dart',
          'test/extensions/crash_report/consent_gate_crash_reporter_test.dart',
          'test/extensions/crash_report/pii_scrubbing_crash_reporter_test.dart',
          'test/extensions/crash_report/safe_crash_reporter_test.dart',
          'test/extensions/crash_report/crash_report_config_test.dart',
          'test/extensions/crash_report/crash_report_failure_mapper_test.dart',
          'test/extensions/crash_report/crash_report_support_test.dart',
          'test/extensions/crash_report/crash_report_module_test.dart',
          'test/extensions/crash_report/gate_crash_report_test.dart',
          'test/extensions/crash_report/noop_crash_reporter_test.dart',
        ]),
      );

      final config = files.firstWhere(
        (file) => file.relativePath.endsWith('crash_report_config.dart'),
      );
      final source = String.fromCharCodes(config.bytes);
      expect(source, contains("dsn = ''"));
      expect(source, contains("release = ''"));
      expect(source, contains('sampleRate = 1.0'));

      final golden = File(
        p.join(
          Directory.current.path,
          'test',
          'goldens',
          'rendered',
          'lib',
          'extensions',
          'crash_report',
          'crash_report_config.dart.golden',
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
