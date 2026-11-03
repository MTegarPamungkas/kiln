import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:path/path.dart' as p;

import '../bundles/app_basic_bundle.dart';
import '../command_context.dart';
import '../infra/exit_codes.dart';
import '../project_context.dart';
import 'command_helpers.dart';

/// Creates a Flutter project from the `app_basic` brick.
final class CreateCommand extends KilnCommand {
  CreateCommand(super.context) {
    argParser
      ..addOption(
        'state',
        defaultsTo: 'none',
        allowed: ['none', 'bloc', 'riverpod'],
      )
      ..addOption('org', defaultsTo: 'com.example')
      ..addOption('description', defaultsTo: 'A Kiln application.')
      ..addOption('platforms', defaultsTo: 'android,ios,web')
      ..addMultiOption('with', help: 'Extensions to install immediately.')
      ..addMultiOption(
        'answer',
        splitCommas: false,
        help: 'Prompt answer as name=value.',
      )
      ..addOption('core-path', help: 'Local path to kiln_core for development.')
      ..addOption(
        'output',
        defaultsTo: '.',
        help: 'Parent directory for the app.',
      )
      ..addFlag('force', negatable: false)
      ..addFlag('yes', abbr: 'y', negatable: false)
      ..addFlag('pub', defaultsTo: true, help: 'Run flutter pub get.');
  }

  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Flutter application from app_basic.';

  @override
  String get invocation => 'kiln create <name> [arguments]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    final name = rest.isEmpty ? null : rest.first;
    if (name == null) {
      usageException('Nama aplikasi wajib diisi.');
    }
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
      usageException('Nama aplikasi harus snake_case, misalnya my_app.');
    }

    final state = argResults!['state'] as String;
    final org = argResults!['org'] as String;
    final description = argResults!['description'] as String;
    final platforms = (argResults!['platforms'] as String)
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final force = argResults!['force'] == true;
    final assumeYes = argResults!['yes'] == true;
    final runPub = argResults!['pub'] == true;
    final corePath = argResults!['core-path'] as String?;
    final output = argResults!['output'] as String;

    final target = Directory(
      p.normalize(p.join(context.cwd.path, output, name)),
    );
    if (target.existsSync() && target.listSync().isNotEmpty && !force) {
      throw KilnException(
        'Folder $name already exists and is not empty',
        code: 'create.target_exists',
        suggestion: 'Use another name or add --force',
      );
    }

    final requested = <String>{
      if (findAvailableExtension('l10n') != null) 'l10n',
      ...(argResults!['with'] as List<String>),
      if (state != 'none') state,
    };
    if (requested.isNotEmpty) {
      for (final id in requested) {
        if (findAvailableExtension(id) == null) {
          throw KilnException(
            'Extension "$id" is not available in the bundled catalog',
            code: 'catalog.missing',
            suggestion:
                'Available: ${extensionCatalog.map((e) => e.id).join(', ')}',
          );
        }
      }
    }

    final createResult = await processRunner.flutter(<String>[
      'create',
      '--project-name',
      name,
      '--org',
      org,
      '--platforms',
      platforms.join(','),
      '--no-pub',
      target.path,
    ]);
    if (createResult.exitCode != 0) {
      throw KilnException(
        'flutter create failed',
        code: 'create.flutter_failed',
        details: <String, Object?>{
          'stdout': createResult.stdout,
          'stderr': createResult.stderr,
        },
      );
    }

    _applyCreatePatches(target);

    final rendered = await const BrickRenderer().render(
      bundle: appBasicBundle,
      vars: <String, dynamic>{
        'name': name,
        'description': description,
        'org': org,
        'state': state,
        'platforms': platforms,
      },
    );
    for (final file in rendered) {
      fileSystem.writeAsBytes(
        p.join(target.path, file.relativePath),
        file.bytes,
      );
    }
    final generatedWidgetTest = p.join(target.path, 'test', 'widget_test.dart');
    if (fileSystem.fileExists(generatedWidgetTest)) {
      fileSystem.delete(generatedWidgetTest);
    }

    _writePubspec(target, corePath: corePath);

    if (requested.isNotEmpty) {
      final resolver = ExtensionResolver(extensionCatalog);
      final plan = resolver.resolve(
        installed: const <String>{},
        requested: requested,
        hostCapabilities: const <String>{'app_basic'},
      );
      final answers = answersForPlan(
        plan.added,
        saved: const <String, Map<String, Object?>>{},
        provided: parseAnswerOptions(
          (argResults!['answer'] as List<String>).cast<String>(),
        ),
        prompter: prompter.withAssumeYes(assumeYes),
      );

      final installer = ExtensionInstaller(
        projectRoot: target,
        available: extensionCatalog,
      );
      final result = await installer.add(
        requested: requested.toList(growable: false),
        project: <String, Object?>{
          'name': name,
          'org': org,
          'state': state,
          'platforms': platforms,
        },
        answers: answers,
        options: const InstallOptions(
          verify: false,
          collisionPolicy: CollisionPolicy.ask,
        ),
        hostCapabilities: const <String>{'app_basic'},
      );
      if (result.hasConflicts) {
        throw KilnException(
          'Files conflict while installing extensions',
          code: 'install.conflict',
          suggestion: result.warnings.join('\n'),
        );
      }

      final project = ProjectContext.find(target);
      if (project != null) {
        for (final extension in result.plan.added) {
          project.updateExtensionAnswers(
            extension.id,
            answers[extension.id] ?? const <String, Object?>{},
          );
        }
      }
      if (result.plan.added.isNotEmpty) {
        logger.info(
          'Installed extension(s): ${result.plan.added.map((e) => e.id).join(', ')}',
        );
      }
    }

    if (runPub) {
      final pubResult = await processRunner.flutter(<String>[
        'pub',
        'get',
      ], workingDirectory: target.path);
      if (pubResult.exitCode != 0) {
        throw KilnException(
          'flutter pub get failed in the new project',
          code: 'verification.pub_get',
          details: <String, Object?>{
            'stdout': pubResult.stdout,
            'stderr': pubResult.stderr,
          },
        );
      }
    }

    logger.success('Project $name created at ${target.path}');
    logger.info('Berikutnya:');
    logger.info('  cd ${p.relative(target.path, from: context.cwd.path)}');
    logger.info(requested.isEmpty ? '  kiln add dio' : '  flutter run');
    return ExitCodes.success;
  }

  void _writePubspec(Directory target, {String? corePath}) {
    final pubspecFile = File(p.join(target.path, 'pubspec.yaml'));
    final source = pubspecFile.readAsStringSync();
    final writer = PubspecWriter(pubspecFile);
    var edited = source;

    if (corePath != null) {
      final normalizedCore = corePath.replaceAll('\\', '/');
      edited = writer.editedWithDependencyValue(
        edited,
        'kiln_core',
        <String, Object?>{'path': normalizedCore},
      );
      edited = writer.editedWithDependencyOverride(
        edited,
        'kiln_core',
        <String, Object?>{'path': normalizedCore},
      );
      final testingPath = Directory(p.join(corePath, '..', 'kiln_testing'));
      if (testingPath.existsSync()) {
        edited = writer.editedWithDevDependencyValue(
          edited,
          'kiln_testing',
          <String, Object?>{
            'path': p.normalize(testingPath.path).replaceAll('\\', '/'),
          },
        );
      }
    } else {
      edited = writer.editedWithDependency(edited, 'kiln_core', '^0.1.0');
      edited = writer.editedWithDevDependency(edited, 'kiln_testing', '^0.1.0');
    }

    if (!edited.contains('flutter_lints')) {
      edited = writer.editedWithDevDependency(
        edited,
        'flutter_lints',
        '^6.0.0',
      );
    }
    pubspecFile.writeAsStringSync(edited);
  }

  /// Applies mobile patches that every generated app benefits from.
  void _applyCreatePatches(Directory target) {
    final files = ProjectFiles(target);
    const AndroidGradleDesugaringPatch().apply(files);
    for (final entry in files.changes.entries) {
      final file = File(p.join(target.path, entry.key));
      final content = entry.value;
      if (content == null) {
        if (file.existsSync()) {
          file.deleteSync();
        }
      } else {
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(content);
      }
    }
  }
}
