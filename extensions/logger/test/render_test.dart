import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('logger brick renders the expected files', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(project: const {'name': 'logger_app'});

    expect(
      files.map((file) => file.relativePath),
      containsAll(<String>[
        'lib/extensions/logger/logger_module.dart',
        'lib/extensions/logger/console_logger.dart',
        'lib/extensions/logger/logger_config.dart',
        'lib/extensions/logger/log_sink.dart',
        'lib/extensions/logger/log_formatter.dart',
        'lib/extensions/logger/sink_pipeline.dart',
        'lib/extensions/logger/redacting_sink.dart',
        'lib/extensions/logger/memory_log_sink.dart',
        'lib/extensions/logger/file_log_sink.dart',
        'lib/extensions/logger/breadcrumb_sink.dart',
        'lib/extensions/logger/log_level_controller.dart',
        'lib/extensions/logger/log_exporter.dart',
        'lib/extensions/logger/http_log_middleware.dart',
        'test/extensions/logger/logger_contract_test.dart',
        'test/extensions/logger/file_log_sink_test.dart',
      ]),
    );

    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('logger_config.dart'),
    );
    final source = String.fromCharCodes(config.bytes);
    expect(source, contains('LogSinkKind.file,'));
    expect(source, contains('httpLoggingEnabled = true'));
    expect(source, contains('redactionEnabled = true'));
  });

  test('disabling the prompts keeps a valid configuration', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render(
      answers: const <String, Object?>{
        'file_sink': false,
        'http_logging': false,
      },
      project: const {'name': 'logger_app'},
    );

    final config = files.firstWhere(
      (file) => file.relativePath.endsWith('logger_config.dart'),
    );
    final source = String.fromCharCodes(config.bytes);
    expect(source, isNot(contains('LogSinkKind.file,')));
    expect(source, contains('httpLoggingEnabled = false'));
    expect(
      files.map((file) => file.relativePath),
      contains('lib/extensions/logger/file_log_sink.dart'),
    );
  });
}
