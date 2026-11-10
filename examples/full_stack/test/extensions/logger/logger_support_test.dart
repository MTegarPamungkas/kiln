import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/logger/logger_config.dart';
import 'package:full_stack/extensions/logger/logger_support.dart';

void main() {
  test('reports file and memory sinks when the probe succeeds', () async {
    final support = LoggerSupport(
      config: LoggerConfig.defaults,
      fileProbe: () async => true,
    );

    final info = await support.check();

    expect(info.isSupported, isTrue);
    expect(info.details['file'], isTrue);
    expect(info.details['memory'], isTrue);
  });

  test('degrades to other sinks when the file probe fails', () async {
    final support = LoggerSupport(
      config: LoggerConfig.defaults,
      fileProbe: () async => false,
    );

    final info = await support.check();

    expect(info.isSupported, isTrue);
    expect(info.details['file'], isFalse);
    expect(info.message, contains('File logging is unavailable'));
  });

  test('does not probe the file sink when it is disabled', () async {
    var calls = 0;
    final support = LoggerSupport(
      config: const LoggerConfig(
        activeSinks: <LogSinkKind>{LogSinkKind.memory},
      ),
      fileProbe: () async {
        calls++;
        return true;
      },
    );

    final info = await support.check();

    expect(calls, 0);
    expect(info.details['file'], isFalse);
    expect(info.details['memory'], isTrue);
  });

  test('rejects an invalid memory capacity', () async {
    final support = LoggerSupport(
      config: const LoggerConfig(memoryCapacity: 0),
      fileProbe: () async => false,
    );

    final info = await support.check();

    expect(info.state, SupportState.notConfigured);
    expect(info.toFailure().kind, FailureKind.configuration);
  });
}
