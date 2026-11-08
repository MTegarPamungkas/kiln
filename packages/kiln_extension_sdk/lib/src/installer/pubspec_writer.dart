import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Adds and removes dependencies while preserving the rest of the file.
final class PubspecWriter {
  const PubspecWriter(this.file);

  final File file;

  void addDependency(String name, String constraint) {
    file.writeAsStringSync(
      editedWithDependency(file.readAsStringSync(), name, constraint),
    );
  }

  void addDevDependency(String name, String constraint) {
    file.writeAsStringSync(
      editedWithDevDependency(file.readAsStringSync(), name, constraint),
    );
  }

  void addDependencyValue(String name, Object? value) {
    file.writeAsStringSync(
      editedWithDependencyValue(file.readAsStringSync(), name, value),
    );
  }

  void addDevDependencyValue(String name, Object? value) {
    file.writeAsStringSync(
      editedWithDevDependencyValue(file.readAsStringSync(), name, value),
    );
  }

  void removeDependency(String name) {
    file.writeAsStringSync(
      editedWithoutDependency(file.readAsStringSync(), name),
    );
  }

  void removeDevDependency(String name) {
    file.writeAsStringSync(
      editedWithoutDevDependency(file.readAsStringSync(), name),
    );
  }

  String editedWithDependency(String source, String name, String constraint) =>
      _add(source, 'dependencies', name, constraint);

  String editedWithDevDependency(
    String source,
    String name,
    String constraint,
  ) => _add(source, 'dev_dependencies', name, constraint);

  String editedWithDependencyValue(String source, String name, Object? value) =>
      _add(source, 'dependencies', name, value);

  String editedWithDevDependencyValue(
    String source,
    String name,
    Object? value,
  ) => _add(source, 'dev_dependencies', name, value);

  String editedWithDependencyOverride(
    String source,
    String name,
    Object? value,
  ) => _add(source, 'dependency_overrides', name, value);

  /// Enables or disables Flutter's gen-l10n code generation.
  String editedWithFlutterGenerate(String source, {bool generate = true}) {
    final editor = YamlEditor(source);
    var root = editor.parseAt(<Object>[]);
    if (root is! YamlMap) {
      if (!generate) {
        return source;
      }
      editor.update(<Object>[], <String, Object?>{});
      root = editor.parseAt(<Object>[]);
    }
    if (root is YamlMap && !root.containsKey('flutter')) {
      if (!generate) {
        return source;
      }
      editor.update(<Object>['flutter'], <String, Object?>{});
    }
    final flutter = editor.parseAt(<Object>['flutter']);
    if (flutter is! YamlMap) {
      return source;
    }
    if (!generate && flutter['generate'] != true) {
      return source;
    }
    editor.update(<Object>['flutter', 'generate'], generate);
    return editor.toString();
  }

  String editedWithoutDependency(String source, String name) =>
      _remove(source, 'dependencies', name);

  /// Removes a whole root section, if it exists.
  String editedWithoutSection(String source, String section) {
    final editor = YamlEditor(source);
    final root = editor.parseAt(<Object>[]);
    if (root is! YamlMap || !root.containsKey(section)) {
      return source;
    }
    editor.remove(<Object>[section]);
    return editor.toString();
  }

  String editedWithoutDevDependency(String source, String name) =>
      _remove(source, 'dev_dependencies', name);

  String _add(String source, String section, String name, Object? value) {
    final editor = YamlEditor(source);
    var root = editor.parseAt(<Object>[]);
    if (root is! YamlMap) {
      editor.update(<Object>[], <String, Object?>{});
      root = editor.parseAt(<Object>[]);
    }
    if (root is YamlMap && !root.containsKey(section)) {
      editor.update(<Object>[section], <String, Object?>{});
    }
    editor.update(<Object>[section, name], value);
    return editor.toString();
  }

  String _remove(String source, String section, String name) {
    final editor = YamlEditor(source);
    final root = editor.parseAt(<Object>[]);
    if (root is! YamlMap || !root.containsKey(section)) {
      return source;
    }
    final node = editor.parseAt(<Object>[section]);
    if (node is! YamlMap || !node.containsKey(name)) {
      return source;
    }
    editor.remove(<Object>[section, name]);
    return editor.toString();
  }
}
