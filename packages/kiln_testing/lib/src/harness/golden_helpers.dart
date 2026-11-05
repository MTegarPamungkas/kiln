import 'package:flutter_test/flutter_test.dart';

/// Compares [finder] with a golden file relative to the test file.
Future<void> expectGoldenWidget(
  WidgetTester tester,
  Finder finder,
  String goldenFile,
) async {
  await expectLater(finder, matchesGoldenFile(goldenFile));
}
