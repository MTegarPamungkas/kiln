import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

/// Renders the compatible extension set into one application and checks that it
/// really composes.
///
/// The 34 official extensions cannot all live in one application: four provide
/// `auth`, two provide `push_transport`, and two provide a state capability, and
/// [ModuleGraph] rejects duplicate providers. Alternatives also ship the same
/// `lib/features/notes/...` files (for example `bloc` and `riverpod`), so only
/// the selected representative of each capability is rendered here.
/// `tool/verify_extensions.dart` still renders and checks every extension on its
/// own.
const String _appName = 'verify_composed';

/// One compatible representative per capability.
///
/// Excluded on purpose: `codegen` (build-time, no runtime module), the three
/// other auth backends, `notifications`, `appwrite_push_native` (another
/// `push_transport`), and `riverpod` (another state capability).
const List<String> _selectedIds = <String>[
  'analytics',
  'appwrite',
  'appwrite_push',
  'biometric',
  'bloc',
  'calendar',
  'connectivity',
  'crash_report',
  'deep_link',
  'dio',
  'env',
  'flavors',
  'geolocation',
  'go_router',
  'http_cache',
  'http_retry',
  'image_picker',
  'l10n',
  'local_db',
  'logger',
  'permission',
  'remote_config',
  'secure_storage',
  'share',
  'social_login',
  'storage',
  'theme',
];

Future<void> main(List<String> arguments) async {
  final analyzer = arguments.contains('--analyze');
  final tester = arguments.contains('--test');
  final keep = arguments.contains('--keep');
  final root = Directory.current.absolute;

  final extensions = <_ComposedExtension>[];
  final extensionDirs =
      Directory(p.join(root.path, 'extensions'))
          .listSync()
          .whereType<Directory>()
          .where(
            (directory) =>
                File(p.join(directory.path, 'extension.yaml')).existsSync(),
          )
          .toList(growable: false)
        ..sort((left, right) => left.path.compareTo(right.path));

  for (final directory in extensionDirs) {
    final manifest = ExtensionManifest.parse(
      File(p.join(directory.path, 'extension.yaml')).readAsStringSync(),
      rootPath: directory.path,
    );
    final bundle = createBundle(Directory(p.join(directory.path, 'brick')));
    final files = await const BrickRenderer().render(
      bundle: bundle,
      vars: _vars(manifest, bundle),
    );
    extensions.add(
      _ComposedExtension(manifest: manifest, files: files),
    );
  }

  final byId = <String, _ComposedExtension>{
    for (final extension in extensions) extension.manifest.id: extension,
  };
  final missing = _selectedIds.where((id) => !byId.containsKey(id)).toList();
  if (missing.isNotEmpty) {
    stderr.writeln('Unknown selected extensions: ${missing.join(', ')}');
    exitCode = 1;
    return;
  }
  final selected = <_ComposedExtension>[
    for (final id in _selectedIds) byId[id]!,
  ];
  final problems = <String>[];
  _checkSelection(selected, extensions, problems);
  if (problems.isNotEmpty) {
    for (final problem in problems) {
      stderr.writeln('[composition] $problem');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'composing ${selected.length} modules from ${extensions.length} '
    'extensions: ${selected.map((extension) => extension.manifest.id).join(', ')}',
  );

  final temp = await Directory.systemTemp.createTemp('kiln_composed_');
  stdout.writeln('fixture: ${temp.path}');
  try {
    final appBundle = createBundle(
      Directory(p.join(root.path, 'bricks', 'app_basic')),
    );
    final appFiles = await const BrickRenderer().render(
      bundle: appBundle,
      vars: const <String, dynamic>{
        'name': _appName,
        'description': 'Composed Kiln extension fixture.',
        'org': 'dev.kiln',
        'state': 'none',
        'platforms': <String>['android', 'ios', 'web'],
        'minimal': false,
      },
    );

    Future<void> writeFile(RenderedFile file) async {
      final target = File(p.join(temp.path, file.relativePath));
      await target.parent.create(recursive: true);
      await target.writeAsBytes(file.bytes);
    }

    for (final file in appFiles) {
      await writeFile(file);
    }
    final owners = <String, String>{};
    for (final extension in selected) {
      for (final file in extension.files) {
        final existing = owners[file.relativePath];
        if (existing != null && existing != extension.manifest.id) {
          problems.add(
            '${file.relativePath} is rendered by $existing and '
            '${extension.manifest.id}',
          );
          continue;
        }
        owners[file.relativePath] = extension.manifest.id;
        await writeFile(file);
      }
    }
    if (problems.isNotEmpty) {
      for (final problem in problems) {
        stderr.writeln('[composition] $problem');
      }
      exitCode = 1;
      return;
    }

    final generated = const ExtensionsCodegen().build(
      <String, LockedExtension>{
        for (final extension in selected)
          extension.manifest.id: LockedExtension(
            version: extension.manifest.version,
            source: ExtensionSource.bundled,
            files: <String, String>{
              'lib/extensions/${extension.manifest.id}/'
                  '${extension.manifest.id}_module.dart': '',
            },
          ),
      },
    );
    await File(
      p.join(temp.path, ExtensionsCodegen.relativePath),
    ).writeAsString(generated);

    await File(p.join(temp.path, 'pubspec.yaml')).writeAsString(
      _pubspec(root: root, extensions: selected),
    );

    final compositionDir = Directory(
      p.join(temp.path, 'test', 'composition'),
    );
    await compositionDir.create(recursive: true);
    await File(
      p.join(compositionDir.path, 'composed_modules_test.dart'),
    ).writeAsString(_compositionTest(selected.length, _selectedIds));

    if (analyzer || tester) {
      final pubGet = await _run('flutter', <String>['pub', 'get'], temp);
      if (pubGet != 0) {
        stderr.writeln('flutter pub get failed in the composed fixture.');
        exitCode = 1;
        return;
      }
    }
    if (analyzer) {
      final result = await _run('flutter', <String>['analyze'], temp);
      if (result != 0) {
        stderr.writeln('Composed analysis failed.');
        exitCode = 1;
        return;
      }
      stdout.writeln('analyzed $_appName');
    }
    if (tester) {
      final result = await _run(
        'flutter',
        <String>['test', 'test/composition'],
        temp,
      );
      if (result != 0) {
        stderr.writeln('Composed tests failed.');
        exitCode = 1;
        return;
      }
      stdout.writeln('tested $_appName');
    }
  } finally {
    if (!keep) {
      try {
        await temp.delete(recursive: true);
      } on FileSystemException {
        // A killed analyzer or test can hold a handle briefly on Windows.
      }
    }
  }
}

Map<String, dynamic> _vars(ExtensionManifest manifest, MasonBundle bundle) {
  final vars = <String, dynamic>{'id': manifest.id, 'app_name': _appName};
  for (final prompt in manifest.prompts) {
    if (prompt.defaultValue != null) {
      vars[prompt.name] = prompt.defaultValue;
      continue;
    }
    vars[prompt.name] = switch (prompt.type) {
      PromptType.url => 'https://api.example.com',
      PromptType.secret => 'test-secret',
      PromptType.intValue => prompt.min ?? 1,
      PromptType.boolValue => false,
      PromptType.enumValue =>
        prompt.options.isEmpty ? 'default' : prompt.options.first,
      PromptType.multi =>
        prompt.options.isEmpty ? <String>[] : <String>[prompt.options.first],
      PromptType.string => 'sample',
    };
  }
  return buildTemplateVars(
    extension: AvailableExtension(manifest: manifest, bundle: bundle),
    answers: vars,
    project: const <String, dynamic>{'name': _appName},
  );
}

void _checkSelection(
  List<_ComposedExtension> selected,
  List<_ComposedExtension> all,
  List<String> problems,
) {
  final providers = <String, String>{};
  for (final extension in selected) {
    if (!extension.files.any(
      (file) =>
          file.relativePath ==
          'lib/extensions/${extension.manifest.id}/'
              '${extension.manifest.id}_module.dart',
    )) {
      problems.add(
        '${extension.manifest.id} is selected but has no runtime module',
      );
      continue;
    }
    for (final capability in extension.manifest.provides) {
      final existing = providers[capability];
      if (existing != null) {
        problems.add(
          'capability "$capability" is provided by $existing and '
          '${extension.manifest.id}',
        );
        continue;
      }
      providers[capability] = extension.manifest.id;
    }
  }
  for (final extension in selected) {
    for (final capability in extension.manifest.requires) {
      if (!providers.containsKey(capability)) {
        problems.add(
          '${extension.manifest.id} requires "$capability" but the composed '
          'set does not provide it',
        );
      }
    }
  }

  final collisions = <String, List<String>>{};
  for (final extension in all) {
    for (final capability in extension.manifest.provides) {
      collisions.putIfAbsent(capability, () => <String>[]).add(
        extension.manifest.id,
      );
    }
  }
  final shared = collisions.entries.where((entry) => entry.value.length > 1);
  for (final entry in shared) {
    stdout.writeln(
      'capability "${entry.key}" is provided by '
      '${entry.value.join(', ')}; selecting one',
    );
  }
}

String _pubspec({
  required Directory root,
  required List<_ComposedExtension> extensions,
}) {
  final core = p
      .join(root.path, 'packages', 'kiln_core')
      .replaceAll('\\', '/');
  final testing = p
      .join(root.path, 'packages', 'kiln_testing')
      .replaceAll('\\', '/');
  final dependencies = <String, String>{};
  final declaredBy = <String, String>{};
  var generate = false;
  for (final extension in extensions) {
    final flutterConfig = extension.manifest.raw['flutter'];
    if (flutterConfig is Map && flutterConfig['generate'] == true) {
      generate = true;
    }
    for (final entry in extension.manifest.dependencies.entries) {
      if (entry.key == 'kiln_core' ||
          entry.key == 'flutter' ||
          entry.key == 'flutter_test') {
        continue;
      }
      final value = '${entry.value}';
      final existing = dependencies[entry.key];
      if (existing == null || existing == value) {
        dependencies[entry.key] = value;
        declaredBy[entry.key] ??= extension.manifest.id;
        continue;
      }
      final chosen = _stricter(existing, value);
      stdout.writeln(
        '${entry.key}: $existing (${declaredBy[entry.key]}) and $value '
        '(${extension.manifest.id}); using $chosen',
      );
      dependencies[entry.key] = chosen;
    }
  }
  final buffer = StringBuffer()
    ..writeln('name: $_appName')
    ..writeln('publish_to: none')
    ..writeln('environment:')
    ..writeln('  sdk: ^3.13.0')
    ..writeln('dependencies:')
    ..writeln('  flutter:')
    ..writeln('    sdk: flutter')
    ..writeln('  material_ui: ^1.11.1')
    ..writeln('  kiln_core:')
    ..writeln('    path: $core');
  final names = dependencies.keys.toList()..sort();
  for (final name in names) {
    buffer.writeln('  $name: ${dependencies[name]}');
  }
  buffer
    ..writeln('dev_dependencies:')
    ..writeln('  flutter_test:')
    ..writeln('    sdk: flutter')
    ..writeln('  flutter_lints: ^6.0.0')
    ..writeln('  kiln_testing:')
    ..writeln('    path: $testing')
    ..writeln('dependency_overrides:')
    ..writeln('  kiln_core:')
    ..writeln('    path: $core');
  if (generate) {
    buffer
      ..writeln('flutter:')
      ..writeln('  generate: true');
  }
  return buffer.toString();
}

/// Prefers the caret constraint with the higher version when two extensions
/// disagree. `pub` resolves the remaining compatible ranges itself.
String _stricter(String left, String right) {
  int? version(String constraint) {
    if (!constraint.startsWith('^')) {
      return null;
    }
    final parts = constraint.substring(1).split('.');
    if (parts.isEmpty || parts.length > 3) {
      return null;
    }
    var value = 0;
    for (final part in parts) {
      final parsed = int.tryParse(part);
      if (parsed == null) {
        return null;
      }
      value = value * 1000 + parsed;
    }
    return value;
  }

  final leftVersion = version(left);
  final rightVersion = version(right);
  if (leftVersion == null || rightVersion == null) {
    return left;
  }
  return rightVersion > leftVersion ? right : left;
}

String _compositionTest(int moduleCount, List<String> ids) {
  final expected = (ids.toList()..sort())
      .map((id) => "        '$id',")
      .join('\n');
  return '''
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:$_appName/extensions/extensions.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the module list is the reviewed compatible set', () {
    final modules = kilnModules();

    expect(modules, hasLength($moduleCount));
    expect(
      modules.map((module) => module.id).toSet(),
      <String>{
$expected
      },
    );
    expect(modules.map((module) => module.id).toSet(), hasLength(modules.length));
    final providers = <String, String>{};
    for (final module in modules) {
      for (final capability in module.provides) {
        expect(
          providers.containsKey(capability),
          isFalse,
          reason: '\$capability is provided by \${providers[capability]} and \${module.id}',
        );
        providers[capability] = module.id;
      }
    }
    expect(
      providers.keys,
      containsAll(<String>[
        'auth',
        'token_provider',
        'account_management',
        'storage',
        'local_db',
        'http_client',
        'http_pipeline',
        'navigation',
      ]),
    );
  });

  test('randomized input order never breaks required provider ordering', () {
    final random = Random(20261121);
    for (var attempt = 0; attempt < 25; attempt++) {
      final modules = kilnModules()..shuffle(random);
      final ordered = ModuleGraph(modules).resolve();
      final position = <String, int>{
        for (var index = 0; index < ordered.length; index++)
          ordered[index].id: index,
      };
      for (final module in ordered) {
        for (final capability in module.requires) {
          final provider = ordered.firstWhere(
            (candidate) => candidate.provides.contains(capability),
          );
          expect(
            position[provider.id]!,
            lessThan(position[module.id]!),
            reason: '\$capability provider must precede \${module.id}',
          );
        }
      }
    }
  });

  test('registration in a resolved random order exposes core contracts', () async {
    final modules = kilnModules()..shuffle(Random(7));
    final ordered = ModuleGraph(modules).resolve();
    final registry = GetItRegistry();
    // Mirror the host services KilnBootstrap registers before modules. A bare
    // module set without them cannot register slots, consent, lifecycle or
    // support-aware modules.
    final slots = SlotRegistry();
    final session = SessionController();
    final consent = ConsentController();
    final lifecycle = LifecycleController();
    registry
      ..registerSingleton<SlotRegistry>(slots)
      ..registerSingleton<SessionController>(session)
      ..registerSingleton<ConsentController>(consent)
      ..registerSingleton<LifecycleController>(lifecycle)
      ..registerSingleton<Lifecycle>(lifecycle)
      ..registerSingleton<Clock>(const SystemClock())
      ..registerSingleton<SupportRegistry>(SupportRegistry())
      ..registerSingleton<Gate>(Gate(registry));
    for (final module in ordered) {
      module.register(registry);
    }

    expect(registry.isRegistered<TokenProvider>(), isTrue);
    expect(registry.isRegistered<AccountManagement>(), isTrue);
    expect(registry.isRegistered<AuthRepository>(), isTrue);
    expect(registry.isRegistered<Storage>(), isTrue);
    expect(registry.isRegistered<LocalDatabase>(), isTrue);
    expect(registry.isRegistered<RemoteDatabase>(), isTrue);
    expect(registry.isRegistered<FileStorage>(), isTrue);
    expect(registry.isRegistered<HttpClient>(), isTrue);
    expect(registry.isRegistered<AppLogger>(), isTrue);

    for (final module in ordered.reversed) {
      try {
        await module.dispose();
      } on Object {
        // A module that never opened a resource may still throw on shutdown.
      }
    }
  });
}
''';
}

Future<int> _run(String command, List<String> arguments, Directory directory) {
  return Process.run(
    command,
    arguments,
    workingDirectory: directory.path,
    runInShell: Platform.isWindows,
  ).then((result) {
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    return result.exitCode;
  });
}

final class _ComposedExtension {
  _ComposedExtension({required this.manifest, required this.files});

  final ExtensionManifest manifest;
  final List<RenderedFile> files;
}
