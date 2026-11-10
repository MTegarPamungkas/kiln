import 'dart:io';

import 'package:kiln_extension_sdk/testing.dart';
import 'package:test/test.dart';

void main() {
  test('brick renders without errors', () async {
    final harness = ExtensionTestHarness(extensionRoot: Directory.current);

    final files = await harness.render();

    expect(files, isNotEmpty);
  });
}
