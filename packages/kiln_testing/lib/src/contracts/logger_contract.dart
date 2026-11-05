import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

/// Observable state a test needs from an [AppLogger] implementation.
abstract interface class LoggerContractHarness {
  AppLogger get logger;

  List<LogRecord> get records;
}

/// Behavior every [AppLogger] implementation must share.
void loggerContract({
  required LoggerContractHarness Function() create,
  String description = 'AppLogger',
}) {
  group('$description contract', () {
    test('convenience methods use the matching level', () {
      final harness = create();
      final logger = harness.logger;

      logger.trace('trace');
      logger.debug('debug');
      logger.info('info');
      logger.warning('warning');
      logger.error('error');

      expect(harness.records, hasLength(5));
      expect(harness.records.map((record) => record.level), [
        LogLevel.trace,
        LogLevel.debug,
        LogLevel.info,
        LogLevel.warning,
        LogLevel.error,
      ]);
      expect(harness.records.last.message, 'error');
    });

    test('records keep the timestamp, error, and data', () {
      final harness = create();
      final error = StateError('boom');

      harness.logger.info(
        'request failed',
        error: error,
        data: const {'url': '/users'},
      );

      final record = harness.records.single;
      expect(record.timestamp, isNotNull);
      expect(record.error, same(error));
      expect(record.data?['url'], '/users');
    });
  });
}
