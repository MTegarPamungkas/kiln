import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_metadata.dart';

void main() {
  test('every manifest matches its runtime module metadata', () {
    final drifts = checkMetadata(Directory.current);

    expect(drifts, isEmpty, reason: drifts.join('\n'));
  });
}
