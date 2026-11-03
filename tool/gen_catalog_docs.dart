import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  final check = arguments.contains('--check');
  final root = Directory.current;
  final extensions = Directory(p.join(root.path, 'extensions'))
      .listSync()
      .whereType<Directory>()
      .where(
        (directory) =>
            File(p.join(directory.path, 'extension.yaml')).existsSync(),
      )
      .toList(growable: false);

  final manifests = <ExtensionManifest>[
    for (final directory in extensions)
      ExtensionManifest.parse(
        File(p.join(directory.path, 'extension.yaml')).readAsStringSync(),
        rootPath: directory.path,
      ),
  ]..sort((left, right) => left.id.compareTo(right.id));

  final content = _render(manifests);
  final file = File(p.join(root.path, 'docs', 'extensions', 'catalog.md'));
  if (check) {
    final current = file.existsSync() ? file.readAsStringSync() : '';
    if (current != content) {
      stderr.writeln('docs/extensions/catalog.md is out of date');
      exitCode = 1;
    }
    return;
  }
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
  stdout.writeln('wrote docs/extensions/catalog.md');
}

String _render(List<ExtensionManifest> manifests) {
  final buffer = StringBuffer()
    ..writeln('# Katalog extension')
    ..writeln()
    ..writeln('Katalog ini dihasilkan dari manifest extension oleh')
    ..writeln('`tool/gen_catalog_docs.dart`. Jangan diedit manual.')
    ..writeln()
    ..writeln('| Id | Nama | Versi | Kategori | Tier | Provides |')
    ..writeln('| --- | --- | --- | --- | --- | --- |');

  for (final manifest in manifests) {
    buffer.writeln(
      '| `${manifest.id}` | ${manifest.name} | ${manifest.version} | '
      '${manifest.category} | ${manifest.tier.name} | '
      '${manifest.provides.map((value) => '`$value`').join(', ')} |',
    );
  }

  for (final manifest in manifests) {
    buffer
      ..writeln()
      ..writeln('## ${manifest.id}')
      ..writeln()
      ..writeln(manifest.description)
      ..writeln();
    if (manifest.provides.isNotEmpty) {
      buffer.writeln(
        '- Provides: ${manifest.provides.map((value) => '`$value`').join(', ')}',
      );
    }
    if (manifest.requires.isNotEmpty) {
      buffer.writeln(
        '- Requires: ${manifest.requires.map((value) => '`$value`').join(', ')}',
      );
    }
    if (manifest.prompts.isNotEmpty) {
      buffer.writeln(
        '- Prompts: ${manifest.prompts.map((prompt) => prompt.name).join(', ')}',
      );
    }
    if (manifest.dependencies.isNotEmpty) {
      buffer.writeln(
        '- Dependencies: ${manifest.dependencies.entries.map((entry) => '`${entry.key}: ${entry.value}`').join(', ')}',
      );
    }
    if (manifest.platformSetup.platforms.isNotEmpty) {
      buffer.writeln(
        '- Platforms: ${manifest.platformSetup.platforms.join(', ')}',
      );
    }
  }
  return buffer.toString();
}
