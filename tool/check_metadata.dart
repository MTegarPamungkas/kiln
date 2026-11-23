import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:path/path.dart' as p;

/// A difference between an extension manifest and its runtime module.
final class MetadataDrift {
  const MetadataDrift(this.extension, this.field, this.manifest, this.module);

  final String extension;
  final String field;
  final String manifest;
  final String module;

  @override
  String toString() =>
      '$extension: $field manifest=$manifest module=$module';
}

Future<void> main() async {
  final drifts = checkMetadata(Directory.current);
  if (drifts.isEmpty) {
    stdout.writeln('Manifest and module metadata are consistent.');
    return;
  }
  for (final drift in drifts) {
    stderr.writeln('[drift] $drift');
  }
  exitCode = 1;
}

/// Compares every `extension.yaml` with the metadata getters of its module.
List<MetadataDrift> checkMetadata(Directory root) {
  final drifts = <MetadataDrift>[];
  final extensionDirs = Directory(p.join(root.path, 'extensions'))
      .listSync()
      .whereType<Directory>()
      .where(
        (directory) =>
            File(p.join(directory.path, 'extension.yaml')).existsSync(),
      )
      .toList()
    ..sort((left, right) => left.path.compareTo(right.path));

  for (final directory in extensionDirs) {
    final manifest = ExtensionManifest.parse(
      File(p.join(directory.path, 'extension.yaml')).readAsStringSync(),
      rootPath: directory.path,
    );
    final modules = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('_module.dart') &&
              file.path.replaceAll('\\', '/').contains('/brick/__brick__/'),
        )
        .toList();
    if (modules.isEmpty) {
      // Extensions without a runtime module (for example `codegen`).
      continue;
    }
    final primaryName = '${manifest.id}_module.dart';
    final primary = modules.firstWhere(
      (file) => p.basename(file.path) == primaryName,
      orElse: () => modules.first,
    );
    final metadata = _moduleMetadata(primary.readAsStringSync());
    if (metadata == null) {
      drifts.add(
        MetadataDrift(manifest.id, 'module', 'present', 'missing KilnModule'),
      );
      continue;
    }
    _compare(drifts, manifest.id, 'id', <String>{manifest.id}, <String>{
      metadata.id,
    });
    _compare(
      drifts,
      manifest.id,
      'provides',
      manifest.provides.toSet(),
      metadata.provides,
    );
    _compare(
      drifts,
      manifest.id,
      'requires',
      manifest.requires.toSet(),
      metadata.requires,
    );
    _compare(
      drifts,
      manifest.id,
      'optionalRequires',
      manifest.optionalRequires.toSet(),
      metadata.optionalRequires,
    );
    _comparePlatforms(drifts, manifest, metadata);
  }
  return drifts;
}

const Set<String> _allPlatforms = <String>{
  'android',
  'ios',
  'linux',
  'macos',
  'web',
  'windows',
};

/// An empty module set means "every platform", which matches a manifest that
/// lists the whole platform universe. A manifest subset must be mirrored
/// exactly because the runtime uses [KilnModule.platforms] to skip modules.
void _comparePlatforms(
  List<MetadataDrift> drifts,
  ExtensionManifest manifest,
  _ModuleMetadata metadata,
) {
  final expected = manifest.platformSetup.platforms.toSet();
  final actual = metadata.platforms;
  final matchesAll =
      expected.containsAll(_allPlatforms) &&
      (actual.isEmpty || actual.containsAll(_allPlatforms));
  if (matchesAll) {
    return;
  }
  _compare(drifts, manifest.id, 'platforms', expected, actual);
}

void _compare(
  List<MetadataDrift> drifts,
  String extension,
  String field,
  Set<String> manifest,
  Set<String> module,
) {
  if (manifest.length == module.length && manifest.containsAll(module)) {
    return;
  }
  drifts.add(
    MetadataDrift(
      extension,
      field,
      _format(manifest),
      _format(module),
    ),
  );
}

String _format(Set<String> values) {
  final sorted = values.toList()..sort();
  return '{${sorted.join(', ')}}';
}

final class _ModuleMetadata {
  const _ModuleMetadata({
    required this.id,
    required this.provides,
    required this.requires,
    required this.optionalRequires,
    required this.platforms,
  });

  final String id;
  final Set<String> provides;
  final Set<String> requires;
  final Set<String> optionalRequires;
  final Set<String> platforms;
}

_ModuleMetadata? _moduleMetadata(String source) {
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  for (final declaration in unit.declarations.whereType<ClassDeclaration>()) {
    final superclass = declaration.extendsClause?.superclass.name.lexeme;
    if (superclass != 'KilnModule') {
      continue;
    }
    return _ModuleMetadata(
      id: _stringGetter(declaration, 'id') ?? '',
      provides: _setGetter(declaration, 'provides'),
      requires: _setGetter(declaration, 'requires'),
      optionalRequires: _setGetter(declaration, 'optionalRequires'),
      platforms: _setGetter(declaration, 'platforms'),
    );
  }
  return null;
}

Expression? _getterExpression(ClassDeclaration declaration, String name) {
  // analyzer 14 moved class members onto the body node.
  for (final member in declaration.body.members.whereType<MethodDeclaration>()) {
    if (!member.isGetter || member.name.lexeme != name) {
      continue;
    }
    final body = member.body;
    if (body is ExpressionFunctionBody) {
      return body.expression;
    }
    if (body is BlockFunctionBody) {
      for (final statement in body.block.statements) {
        if (statement is ReturnStatement) {
          return statement.expression;
        }
      }
    }
  }
  return null;
}

String? _stringGetter(ClassDeclaration declaration, String name) {
  final expression = _getterExpression(declaration, name);
  if (expression is SimpleStringLiteral) {
    return expression.value;
  }
  if (expression is StringInterpolation) {
    return null;
  }
  return null;
}

Set<String> _setGetter(ClassDeclaration declaration, String name) {
  final expression = _getterExpression(declaration, name);
  if (expression == null) {
    return <String>{};
  }
  if (expression is! SetOrMapLiteral) {
    throw FormatException('$name is not a set literal: $expression');
  }
  final values = <String>{};
  for (final element in expression.elements) {
    if (element is SimpleStringLiteral) {
      values.add(element.value);
    } else {
      throw FormatException('$name contains a non-string element: $element');
    }
  }
  return values;
}
