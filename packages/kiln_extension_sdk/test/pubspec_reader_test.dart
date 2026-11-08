import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('PubspecInfo sources', () {
    late Directory temp;
    late File pubspec;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('kiln_pubspec_reader_');
      pubspec = File('${temp.path}/pubspec.yaml');
    });

    tearDown(() async {
      await temp.delete(recursive: true);
    });

    Future<PubspecInfo> read(String source) async {
      await pubspec.writeAsString(source);
      return PubspecReader(pubspec).read();
    }

    test('reads a plain constraint as hosted', () async {
      final info = await read('''
name: demo
dependencies:
  kiln_core: ^0.1.0
''');

      expect(info.dependencySource('kiln_core'), 'hosted');
      expect(info.gitRef('kiln_core'), isNull);
    });

    test('reads a path dependency', () async {
      final info = await read('''
name: demo
dependencies:
  kiln_core:
    path: ../kiln_core
''');

      expect(info.dependencySource('kiln_core'), 'path');
    });

    test('reads a git dependency and its ref', () async {
      final info = await read('''
name: demo
dependencies:
  kiln_core:
    git:
      url: https://github.com/kiln-dev/kiln.git
      path: packages/kiln_core
      ref: v0.1.0
  kiln_testing:
    git:
      url: https://github.com/kiln-dev/kiln.git
      path: packages/kiln_testing
''');

      expect(info.dependencySource('kiln_core'), 'git');
      expect(info.gitRef('kiln_core'), 'v0.1.0');
      // No ref means the default branch.
      expect(info.gitRef('kiln_testing'), isNull);
    });

    test('reads an sdk dependency and a missing one', () async {
      final info = await read('''
name: demo
dependencies:
  flutter:
    sdk: flutter
''');

      expect(info.dependencySource('flutter'), 'sdk');
      expect(info.dependencySource('kiln_core'), isNull);
    });
  });
}
