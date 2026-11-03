import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/logger/console_logger.dart';
import 'package:full_stack/extensions/logger/log_level_controller.dart';

void main() {
  test('prints records that pass the configured level', () {
    final lines = <String>[];
    final clock = FixedClock(DateTime.utc(2026, 1, 2, 3, 4, 5));
    final controller = LogLevelController(
      initialLevel: LogLevel.info,
      flavor: AppFlavor.development,
    );
    final logger = ConsoleLogger(
      write: lines.add,
      levelController: controller,
      clock: clock,
    );

    logger.debug('hidden');
    logger.info('shown', data: const <String, Object?>{'id': 7});

    expect(lines, hasLength(1));
    expect(lines.single, contains('[INFO] shown'));
    expect(lines.single, contains('2026-01-02T03:04:05.000Z'));
    expect(lines.single, contains('"id":7'));
  });

  test('runtime level changes apply to later records', () {
    final lines = <String>[];
    final controller = LogLevelController(
      initialLevel: LogLevel.error,
      flavor: AppFlavor.staging,
    );
    final logger = ConsoleLogger(
      sink: ConsoleLogSink(writer: lines.add),
      levelController: controller,
    );

    logger.info('first');
    controller.setLevel(LogLevel.debug);
    logger.info('second');

    expect(lines, hasLength(1));
    expect(lines.single, contains('second'));
  });
}
