import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../paths.dart';

/// Global settings stored in `~/.kiln/config.yaml`.
final class GlobalConfig {
  const GlobalConfig({this.registry, this.mirror, this.offline = false});

  factory GlobalConfig.load([String? path]) {
    final file = File(path ?? Paths.globalConfig());
    if (!file.existsSync()) {
      return const GlobalConfig();
    }
    try {
      final document = loadYaml(file.readAsStringSync());
      if (document is! Map) {
        return const GlobalConfig();
      }
      return GlobalConfig(
        registry: document['registry'] as String?,
        mirror: document['mirror'] as String?,
        offline: document['offline'] == true,
      );
    } catch (_) {
      return const GlobalConfig();
    }
  }

  final String? registry;
  final String? mirror;
  final bool offline;

  GlobalConfig copyWith({String? registry, String? mirror, bool? offline}) {
    return GlobalConfig(
      registry: registry ?? this.registry,
      mirror: mirror ?? this.mirror,
      offline: offline ?? this.offline,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    if (registry != null) 'registry': registry,
    if (mirror != null) 'mirror': mirror,
    'offline': offline,
  };

  void save([String? path]) {
    final file = File(path ?? Paths.globalConfig());
    file.parent.createSync(recursive: true);
    final editor = YamlEditor('{}');
    editor.update(<Object>[], toJson());
    file.writeAsStringSync(editor.toString());
  }
}
