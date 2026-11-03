import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/logger/breadcrumb_sink.dart';

void main() {
  test('forwards warning and error records as breadcrumbs', () {
    final reporter = FakeCrashReporter();
    final sink = BreadcrumbSink(reporter: reporter);

    sink.write(_record(LogLevel.info, 'info'));
    sink.write(_record(LogLevel.warning, 'warn', data: const {'order': 42}));
    sink.write(
      _record(LogLevel.error, 'error', error: StateError('boom')),
    );

    expect(reporter.breadcrumbs, hasLength(2));
    expect(reporter.breadcrumbs.first.message, 'warn');
    expect(reporter.breadcrumbs.first.data['level'], 'warning');
    expect(reporter.breadcrumbs.first.data['order'], 42);
    expect(reporter.breadcrumbs.last.message, 'error');
    expect(reporter.breadcrumbs.last.data['level'], 'error');
    expect(reporter.breadcrumbs.last.data['error'], contains('boom'));
  });

  test('a higher threshold skips warnings', () {
    final reporter = FakeCrashReporter();
    final sink = BreadcrumbSink(
      reporter: reporter,
      minimumLevel: LogLevel.error,
    );

    sink.write(_record(LogLevel.warning, 'warn'));
    sink.write(_record(LogLevel.error, 'error'));

    expect(reporter.breadcrumbs.map((crumb) => crumb.message), <String>[
      'error',
    ]);
  });
}

LogRecord _record(
  LogLevel level,
  String message, {
  Object? error,
  Map<String, Object?>? data,
}) {
  return LogRecord(
    level: level,
    message: message,
    timestamp: DateTime.utc(2026, 1, 1),
    error: error,
    data: data,
  );
}
