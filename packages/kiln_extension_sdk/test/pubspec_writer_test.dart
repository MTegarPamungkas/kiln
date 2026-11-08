import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('PubspecWriter', () {
    late Directory temp;
    late File pubspec;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('kiln_pubspec_');
      pubspec = File('${temp.path}/pubspec.yaml');
      await pubspec.writeAsString('''
# Project comment that must survive.
name: demo
description: Demo project
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
''');
    });

    tearDown(() async {
      await temp.delete(recursive: true);
    });

    test('adds a dependency and keeps comments', () {
      PubspecWriter(pubspec).addDependency('dio', '^5.9.0');

      final source = pubspec.readAsStringSync();
      expect(source, contains('# Project comment that must survive.'));
      final yaml = loadYaml(source) as YamlMap;
      expect((yaml['dependencies'] as YamlMap)['dio'], '^5.9.0');
    });

    test('adds SDK map dependencies', () {
      PubspecWriter(
        pubspec,
      ).addDevDependencyValue('custom_lint', <String, Object?>{'sdk': 'dart'});

      final yaml = loadYaml(pubspec.readAsStringSync()) as YamlMap;
      final dev = yaml['dev_dependencies'] as YamlMap;
      expect((dev['custom_lint'] as YamlMap)['sdk'], 'dart');
    });

    test('removes a dependency without touching the others', () {
      final writer = PubspecWriter(pubspec);
      writer.addDependency('dio', '^5.9.0');
      writer.removeDependency('dio');

      final yaml = loadYaml(pubspec.readAsStringSync()) as YamlMap;
      expect((yaml['dependencies'] as YamlMap).containsKey('dio'), isFalse);
      expect(yaml['dependencies'], isNotNull);
    });

    test('removing a missing dependency is a no-op', () {
      final before = pubspec.readAsStringSync();
      PubspecWriter(pubspec).removeDependency('missing');

      expect(pubspec.readAsStringSync(), before);
    });

    test('edited sources can be computed without touching the file', () {
      final edited = PubspecWriter(pubspec)
          .editedWithDependency(pubspec.readAsStringSync(), 'dio', '^5.9.0');

      expect(edited, contains('dio: ^5.9.0'));
      expect(pubspec.readAsStringSync(), isNot(contains('dio')));
    });

    test('enables and disables flutter gen-l10n', () {
      final writer = PubspecWriter(pubspec);
      final enabled = writer.editedWithFlutterGenerate(
        pubspec.readAsStringSync(),
      );
      final yaml = loadYaml(enabled) as YamlMap;

      expect((yaml['flutter'] as YamlMap)['generate'], isTrue);

      final disabled = writer.editedWithFlutterGenerate(
        enabled,
        generate: false,
      );
      final disabledYaml = loadYaml(disabled) as YamlMap;

      expect((disabledYaml['flutter'] as YamlMap)['generate'], isFalse);
      expect(
        writer.editedWithFlutterGenerate(disabled, generate: false),
        disabled,
      );
    });

    test('editedWithoutSection drops a whole root section', () {
      final writer = PubspecWriter(File(''));
      const source = '''
name: demo
dependencies:
  flutter:
    sdk: flutter
dependency_overrides:
  kiln_core:
    path: ../kiln_core
'''; //

      final edited = writer.editedWithoutSection(source, 'dependency_overrides');
      final yaml = loadYaml(edited) as YamlMap;

      expect(yaml.containsKey('dependency_overrides'), isFalse);
      expect((yaml['dependencies'] as YamlMap)['flutter'], isNotNull);
      // A section that is not there is left untouched.
      expect(writer.editedWithoutSection(edited, 'dependency_overrides'), edited);
    });
  });
}
