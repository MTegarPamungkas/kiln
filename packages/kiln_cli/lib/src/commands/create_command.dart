import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:path/path.dart' as p;

import '../bundles/app_basic_bundle.dart';
import '../command_context.dart';
import '../infra/exit_codes.dart';
import '../project_context.dart';
import '../version.dart';
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
      ..addOption(
        'template',
        defaultsTo: 'minimal',
        allowed: ['minimal', 'app'],
        help: 'minimal keeps only the root wiring; app adds the starter page.',
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
      ..addOption(
        'core-path',
        help: 'Local path to the kiln_core package.',
      )
      ..addOption(
        'core-git',
        help:
            'Git URL of the Kiln repository to resolve kiln_core and '
            'kiln_testing from, for example '
            'https://github.com/you/kiln.git.',
      )
      ..addOption(
        'core-ref',
        help: 'Branch, tag, or commit used with --core-git.',
      )
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
  String get description =>
      'Create a new Flutter application from the Kiln template.';

  @override
  String get invocation => 'kiln create <name> [arguments]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    final name = rest.isEmpty ? null : rest.first;
    if (name == null) {
      usageException('The application name is required.');
    }
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
      usageException('The application name must be snake_case, for example my_app.');
    }

    final force = argResults!['force'] == true;
    final assumeYes = argResults!['yes'] == true;
    final runPub = argResults!['pub'] == true;
    final output = argResults!['output'] as String;

    // Without --yes, on an interactive terminal, ask for every option the
    // user did not pass, one by one; each prompt shows its default.
    final canAsk = !assumeYes && prompter.interactive;

    String selectedArg(String name, String question, List<String> options) {
      if (argResults!.wasParsed(name)) {
        return argResults![name] as String;
      }
      final fallback = argResults![name] as String;
      return canAsk
          ? prompter.select(question, options, defaultValue: fallback)
          : fallback;
    }

    String enteredArg(String name, String question) {
      if (argResults!.wasParsed(name)) {
        return argResults![name] as String;
      }
      final fallback = argResults![name] as String;
      return canAsk
          ? prompter.text(question, defaultValue: fallback) ?? fallback
          : fallback;
    }

    final template = selectedArg('template', 'Template:', const <String>[
      'minimal',
      'app',
    ]);
    final state = selectedArg(
      'state',
      'State management:',
      const <String>['none', 'bloc', 'riverpod'],
    );
    final org = enteredArg('org', 'Organization:');
    final description = enteredArg('description', 'Description:');

    List<String> parseCsv(String value) => value
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    final platforms = argResults!.wasParsed('platforms')
        ? parseCsv(argResults!['platforms'] as String)
        : canAsk
        ? await prompter.selectMany(
            'Platforms:',
            const <String>['android', 'ios', 'web', 'windows', 'linux', 'macos'],
            defaults: const <String>{'android', 'ios', 'web'},
          )
        : parseCsv(argResults!['platforms'] as String);
    // l10n is always installed and bloc/riverpod come from the state prompt.
    final extensionOptions = <String>[
      for (final extension in extensionCatalog)
        if (extension.id != 'l10n' &&
            extension.id != 'bloc' &&
            extension.id != 'riverpod')
          extension.id,
    ];
    final withExtensions = argResults!.wasParsed('with')
        ? (argResults!['with'] as List<String>)
        : canAsk
        ? await prompter.selectMany('Extensions to install:', extensionOptions)
        : (argResults!['with'] as List<String>);

    final corePathOption = argResults!['core-path'] as String?;
    final coreGitOption = argResults!['core-git'] as String?;
    final coreRef = argResults!['core-ref'] as String?;
    if (coreGitOption != null && corePathOption != null) {
      throw KilnException(
        'Pass either --core-path or --core-git, not both',
        code: 'create.core_source',
        suggestion:
            '--core-path resolves kiln_core from a local checkout, '
            '--core-git from a git URL',
      );
    }
    if (coreRef != null && coreGitOption == null) {
      throw KilnException(
        '--core-ref needs --core-git',
        code: 'create.core_ref',
        suggestion: 'Pass --core-git <url> --core-ref <branch|tag|commit>',
      );
    }

    var corePath = corePathOption;
    var coreGit = coreGitOption;
    if (coreGit != null) {
      logger.info(
        'Resolving kiln_core from $coreGit'
        '${coreRef == null ? '' : ' at $coreRef'}',
      );
    } else if (corePath == null) {
      // Running inside the workspace: keep the local checkout so edits to
      // kiln_core show up immediately.
      corePath = await (context.corePathDetector ?? _detectedCorePath)();
      if (corePath != null) {
        logger.info('Using the local kiln_core checkout at $corePath');
      }
    }

    // Nothing local: resolve the SDK from the public repository, so a freshly
    // compiled CLI works on a machine without the workspace.
    if (corePath == null && coreGit == null && defaultCoreGitUrl.isNotEmpty) {
      coreGit = defaultCoreGitUrl;
      logger.info(
        'Resolving kiln_core from $coreGit '
        '(pass --core-path for the local checkout)',
      );
    }

    if (corePath == null && coreGit == null) {
      throw KilnException(
        'No kiln_core source found',
        code: 'create.core_missing',
        suggestion:
            'kiln_core is not published on pub.dev. Pass '
            '--core-path <checkout>/packages/kiln_core, or --core-git <url> '
            'to resolve it from the Kiln repository.',
      );
    }

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
      ...withExtensions,
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
        'minimal': template == 'minimal',
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

    _writePubspec(target, corePath: corePath, coreGit: coreGit, coreRef: coreRef);

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
          suggestion: coreGit != null
              ? 'Check that $coreGit is reachable and that --core-ref exists'
              : corePath == null
              ? 'kiln_core has no published release yet; pass '
                    '--core-path <checkout>/packages/kiln_core or '
                    '--core-git <url>'
              : null,
          details: <String, Object?>{
            'stdout': pubResult.stdout,
            'stderr': pubResult.stderr,
          },
        );
      }
    }

    logger.success('Project $name created at ${target.path}');
    logger.info('Next steps:');
    logger.info('  cd ${p.relative(target.path, from: context.cwd.path)}');
    logger.info(requested.isEmpty ? '  kiln add dio' : '  flutter run');
    return ExitCodes.success;
  }

  void _writePubspec(
    Directory target, {
    String? corePath,
    String? coreGit,
    String? coreRef,
  }) {
    final pubspecFile = File(p.join(target.path, 'pubspec.yaml'));
    final source = pubspecFile.readAsStringSync();
    final writer = PubspecWriter(pubspecFile);
    var edited = source;
    Map<String, Object?>? overrideCore;

    if (coreGit != null) {
      // A git source keeps the app on one source of truth: `kiln_core` and
      // `kiln_testing` only resolve while the repository stays reachable to
      // this machine, which is how the SDK is shared without pub.dev.
      Map<String, Object?> gitSource(String path) => <String, Object?>{
        'git': <String, Object?>{
          'url': coreGit,
          if (coreRef != null && coreRef.isNotEmpty) 'ref': coreRef,
          'path': path,
        },
      };
      edited = writer.editedWithDependencyValue(
        edited,
        'kiln_core',
        gitSource('packages/kiln_core'),
      );
      edited = writer.editedWithDevDependencyValue(
        edited,
        'kiln_testing',
        gitSource('packages/kiln_testing'),
      );
      // `kiln_testing` asks for `kiln_core: ^0.1.0`, which pub reads as the
      // hosted source. Pub refuses to resolve one package from two sources, so
      // the app pins the override to the same git revision.
      overrideCore = gitSource('packages/kiln_core');
    } else if (corePath != null) {
      final normalizedCore = corePath.replaceAll('\\', '/');
      edited = writer.editedWithDependencyValue(
        edited,
        'kiln_core',
        <String, Object?>{'path': normalizedCore},
      );
      overrideCore = <String, Object?>{'path': normalizedCore};
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

    if (overrideCore != null) {
      edited = _appendOverrides(edited, overrideCore);
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

  /// Appends `dependency_overrides` as a block mapping at the end of the file.
  ///
  /// yaml_edit adds a new root section right after the last key of the final
  /// mapping, which wedges it inside the `flutter:` block: the commented-out
  /// asset and font examples that follow then become invalid YAML as soon as an
  /// app uncomments one. Writing the section last keeps the document valid.
  String _appendOverrides(String source, Map<String, Object?> core) {
    final stripped = PubspecWriter(
      File(''),
    ).editedWithoutSection(source, 'dependency_overrides').trimRight();
    final buffer = StringBuffer(stripped)
      ..writeln()
      ..writeln()
      ..writeln('dependency_overrides:')
      ..writeln('  kiln_core:');
    _writeYamlBlock(buffer, core, '    ');
    return buffer.toString();
  }

  void _writeYamlBlock(
    StringBuffer buffer,
    Map<String, Object?> map,
    String indent,
  ) {
    for (final entry in map.entries) {
      final value = entry.value;
      if (value is Map) {
        buffer.writeln('$indent${entry.key}:');
        _writeYamlBlock(buffer, <String, Object?>{
          for (final nested in value.entries) '${nested.key}': nested.value,
        }, '$indent  ');
      } else if (value is String) {
        // Quote so Windows paths, URLs, and spaces stay valid YAML.
        buffer.writeln("$indent${entry.key}: '${value.replaceAll("'", "''")}'");
      } else {
        buffer.writeln('$indent${entry.key}: $value');
      }
    }
  }

  /// The kiln_core checkout this CLI itself runs from, so a new app resolves
  /// the framework by path while kiln_core has no published release. Null
  /// when the CLI runs from an installed copy without a checkout nearby.
  Future<String?> _detectedCorePath() async {
    // In an AOT executable, Platform.script mirrors the invoked name (which
    // may not exist), while resolvedExecutable is always the real binary.
    // In a `dart run` checkout it is the other way around, so try both.
    for (final start in <String>[
      Platform.resolvedExecutable,
      Platform.script.toFilePath(),
    ]) {
      final found = _corePathNear(start);
      if (found != null) {
        return found;
      }
    }
    final configUri = await Isolate.packageConfig;
    if (configUri == null) {
      return null;
    }
    try {
      final config = File.fromUri(configUri).readAsStringSync();
      final decoded = jsonDecode(config);
      if (decoded is! Map<String, Object?>) {
        return null;
      }
      final packages = decoded['packages'];
      if (packages is! List<Object?>) {
        return null;
      }
      for (final entry in packages) {
        if (entry is Map<String, Object?> &&
            entry['name'] == 'kiln_extension_sdk') {
          // rootUri is relative to the package config's own location.
          final root = configUri.resolve('${entry['rootUri']}');
          return _corePathNear(File.fromUri(root).path);
        }
      }
    } on Object {
      return null;
    }
    return null;
  }

  /// Walks up from [start] looking for a `packages/kiln_core` checkout.
  String? _corePathNear(String start) {
    var current = p.dirname(start);
    for (var i = 0; i < 6; i++) {
      final candidate = p.join(current, 'packages', 'kiln_core');
      if (File(p.join(candidate, 'pubspec.yaml')).existsSync()) {
        return candidate.replaceAll('\\', '/');
      }
      final parent = p.dirname(current);
      if (parent == current) {
        return null;
      }
      current = parent;
    }
    return null;
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
