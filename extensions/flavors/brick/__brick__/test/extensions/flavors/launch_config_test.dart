import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('launch configurations point to existing entry points', () {
    final decoded = jsonDecode(File('.vscode/launch.json').readAsStringSync());
    final configurations =
        (decoded as Map<String, Object?>)['configurations']
            as List<Object?>;

    expect(configurations, hasLength(3));
    for (final entry in configurations) {
      final map = entry as Map<String, Object?>;
      final program = '${map['program']}'.replaceAll(
        r'${workspaceFolder}/',
        '',
      );
      expect(File(program).existsSync(), isTrue, reason: program);
      expect(map['toolArgs'], isA<List<Object?>>());
    }
  });
}
