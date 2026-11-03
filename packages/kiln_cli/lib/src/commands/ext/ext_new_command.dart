import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:path/path.dart' as p;

import '../../bundles/extension_template_bundle.dart';
import '../../command_context.dart';
import '../../infra/exit_codes.dart';

/// Scaffolds a new extension from `extension_template`.
final class ExtNewCommand extends KilnCommand {
  ExtNewCommand(super.context) {
    argParser
      ..addOption('name', help: 'Human readable extension name.')
      ..addOption('category', defaultsTo: 'tooling')
      ..addOption('provides', help: 'Primary capability.')
      ..addOption(
        'requires',
        defaultsTo: '',
        help: 'Comma separated capabilities.',
      )
      ..addOption('output', defaultsTo: 'extensions')
      ..addFlag('with-hooks', negatable: false)
      ..addFlag('with-native-patch', negatable: false);
  }

  @override
  String get name => 'new';

  @override
  String get description => 'Create a new extension skeleton.';

  @override
  String get invocation => 'kiln ext new <id> [arguments]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      usageException('Specify an extension id.');
    }
    final id = rest.first;
    if (!RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$').hasMatch(id)) {
      usageException('Id extension harus snake_case.');
    }
    final name = argResults!['name'] as String? ?? id;
    final output = Directory(
      p.join(context.cwd.path, argResults!['output'] as String),
    );
    final extensionRoot = Directory(p.join(output.path, id));
    if (extensionRoot.existsSync() && extensionRoot.listSync().isNotEmpty) {
      throw KilnException(
        'Extension $id already exists at ${extensionRoot.path}',
        code: 'ext.exists',
      );
    }

    final files = await const BrickRenderer().render(
      bundle: extensionTemplateBundle,
      vars: <String, dynamic>{
        'id': id,
        'name': name,
        'category': argResults!['category'],
        'provides': argResults!['provides'] ?? id,
        'requires': argResults!['requires'],
        'with_hooks': argResults!['with-hooks'] == true,
        'with_native_patch': argResults!['with-native-patch'] == true,
      },
    );
    for (final file in files) {
      fileSystem.writeAsBytes(
        p.join(output.path, file.relativePath),
        file.bytes,
      );
    }

    if (argResults!['with-hooks'] == true) {
      _writeHooks(extensionRoot);
    }

    logger.success('Extension $id created at ${extensionRoot.path}');
    logger.info('Berikutnya:');
    logger.info('  kiln ext validate ${p.relative(extensionRoot.path)}');
    logger.info('  kiln ext test ${p.relative(extensionRoot.path)}');
    return ExitCodes.success;
  }

  void _writeHooks(Directory extensionRoot) {
    final hooks = Directory(p.join(extensionRoot.path, 'brick', 'hooks'));
    fileSystem.writeAsString(p.join(hooks.path, 'pubspec.yaml'), '''
name: ${p.basename(extensionRoot.path)}_hooks
publish_to: none
environment:
  sdk: ^3.13.0
dependencies:
  mason: ^0.1.3
''');
    fileSystem.writeAsString(p.join(hooks.path, 'pre_gen.dart'), '''
import 'package:mason/mason.dart';

void run(HookContext context) {
  context.logger.info('Validating ${p.basename(extensionRoot.path)} input.');
}
''');
    fileSystem.writeAsString(p.join(hooks.path, 'post_gen.dart'), '''
import 'package:mason/mason.dart';

void run(HookContext context) {
  context.logger.info('${p.basename(extensionRoot.path)} rendered.');
}
''');
  }
}
