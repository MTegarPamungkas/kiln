import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/logger/memory_log_sink.dart';
import 'package:{{app_name}}/extensions/logger/widgets/debug_log_page.dart';

void main() {
  testWidgets('shows buffered records in a non-production flavor', (
    tester,
  ) async {
    final sink = MemoryLogSink();
    final clock = FixedClock(DateTime.utc(2026, 1, 1));
    sink.write(
      LogRecord(
        level: LogLevel.info,
        message: 'first entry',
        timestamp: clock.now(),
      ),
    );
    sink.write(
      LogRecord(
        level: LogLevel.error,
        message: 'second entry',
        timestamp: clock.now(),
        error: StateError('boom'),
      ),
    );

    await tester.pumpWidget(MaterialApp(home: DebugLogPage(sink: sink, flavor: AppFlavor.development)));

    expect(find.text('first entry'), findsOneWidget);
    expect(find.text('second entry'), findsOneWidget);
    expect(find.text('ERROR'), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);
  });

  testWidgets('hides records in production', (tester) async {
    final sink = MemoryLogSink()
      ..write(
        LogRecord(
          level: LogLevel.info,
          message: 'secret entry',
          timestamp: DateTime.utc(2026, 1, 1),
        ),
      );

    await tester.pumpWidget(
      MaterialApp(
        home: DebugLogPage(sink: sink, flavor: AppFlavor.production),
      ),
    );

    expect(find.text('secret entry'), findsNothing);
    expect(find.textContaining('non-production'), findsOneWidget);
  });

  testWidgets('clearing removes the buffered records', (tester) async {
    final sink = MemoryLogSink()
      ..write(
        LogRecord(
          level: LogLevel.info,
          message: 'to clear',
          timestamp: DateTime.utc(2026, 1, 1),
        ),
      );

    await tester.pumpWidget(MaterialApp(home: DebugLogPage(sink: sink, flavor: AppFlavor.development)));
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();

    expect(find.text('to clear'), findsNothing);
    expect(find.text('Belum ada log.'), findsOneWidget);
    expect(sink.isEmpty, isTrue);
  });
}
