import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Pumps frames until [condition] becomes true or [timeout] expires.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
  Duration step = const Duration(milliseconds: 50),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('pumpUntil timed out after $timeout');
    }
    await tester.pump(step);
  }
}

/// Waits until [stream] emits [expected] in order.
Future<void> expectEmitsInOrder<T>(
  Stream<T> stream,
  Iterable<T> expected,
) async {
  await expectLater(stream, emitsInOrder(expected));
}
