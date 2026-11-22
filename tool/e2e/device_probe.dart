import 'dart:convert';
import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

/// Renders a disposable Android device app for a probe mode.
///
/// `--biometric` renders biometric + secure_storage (K06 bulk-read
/// authentication); `--media` renders image_picker (K28 device acceptance).
/// The default renders geolocation + deep_link (K26/K29). All modes log typed
/// outcomes as `KILNPROBE` lines, so the coordinator can read them from
/// `adb logcat`.
///
/// Usage (from the repository root):
///
/// ```
/// dart run tool/e2e/device_probe.dart [--biometric|--media] [--render-only]
/// ```
Future<void> main(List<String> arguments) async {
  final root = Directory.current.path;
  final biometric = arguments.contains('--biometric');
  final media = arguments.contains('--media');
  final oversize = arguments.contains('--oversize');
  final k09 = arguments.contains('--k09');
  final fcm = arguments.contains('--fcm');
  final name = fcm
      ? 'fcm_probe'
      : k09
      ? 'k09_probe'
      : biometric
      ? 'biometric_probe'
      : media || oversize
      ? 'media_probe'
      : 'device_probe';
  final fixture = Directory(p.join(root, '.dart_tool', name));
  await fixture.create(recursive: true);
  if (!Directory(p.join(fixture.path, 'android')).existsSync()) {
    final created = await Process.run('flutter', [
      'create',
      '--platforms=android',
      '--project-name=$name',
      '--org=dev.kiln',
      fixture.path,
    ], runInShell: Platform.isWindows);
    if (created.exitCode != 0) throw StateError('Flutter scaffold failed.');
  }

  final dependencies = <String, Object?>{
    'flutter': <String, Object?>{'sdk': 'flutter'},
    'kiln_core': <String, Object?>{
      'path': p.join(root, 'packages', 'kiln_core').replaceAll('\\', '/'),
    },
  };
  final answers = <String, Object?>{
    if (fcm) ...<String, Object?>{
      // Analytics/crash answers are unused here; the push fixture only needs
      // the appwrite backend and the FCM transport.
    },
    if (k09) ...<String, Object?>{
      // Loopback ingestion so native SDK traffic is observable without an
      // account; reached from the phone through `adb reverse`.
      'api_key': 'phc_kiln_loopback_probe',
      'host': 'http://127.0.0.1:8799',
      'dsn': 'http://public@127.0.0.1:8799/1',
      'release': 'kiln-native-acceptance',
    } else if (biometric) ...<String, Object?>{
      'reason': 'Unlock protected values',
      'grace_seconds': 30,
      'biometric_only': true,
    } else if (media || oversize) ...<String, Object?>{
      'max_bytes': oversize ? 102400 : 5242880,
      'allowed_types': <String>[
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/gif',
      ],
    } else ...<String, Object?>{
      'scheme': 'kiln',
      'hosts': <String>['kiln.dev'],
      'path_prefixes': <String>['/app'],
    },
  };
  final ids = fcm
      ? const <String>['appwrite', 'appwrite_push']
      : k09
      ? const <String>['analytics', 'crash_report']
      : biometric
      ? const <String>['biometric', 'secure_storage']
      : media || oversize
      ? const <String>['image_picker']
      : const <String>['deep_link', 'geolocation'];
  for (final id in ids) {
    final source = Directory(p.join(root, 'extensions', id));
    final manifest = ExtensionManifest.parse(
      File(p.join(source.path, 'extension.yaml')).readAsStringSync(),
      rootPath: source.path,
    );
    final bundle = createBundle(Directory(p.join(source.path, 'brick')));
    final native = const NativeSetup().plan(
      projectRoot: fixture,
      manifest: manifest,
      answers: answers,
    );
    for (final entry in native.changes.entries) {
      if (entry.value != null) {
        await File(p.join(fixture.path, entry.key)).writeAsString(entry.value!);
      }
    }
    dependencies.addAll(manifest.dependencies);
    final files = await const BrickRenderer().render(
      bundle: bundle,
      vars: buildTemplateVars(
        extension: AvailableExtension(manifest: manifest, bundle: bundle),
        project: <String, Object?>{'name': name},
        answers: answers,
      ),
    );
    for (final file in files.where(
      (file) => file.relativePath.startsWith('lib/'),
    )) {
      final target = File(p.join(fixture.path, file.relativePath));
      await target.parent.create(recursive: true);
      await target.writeAsBytes(file.bytes);
    }
  }

  await File(p.join(fixture.path, 'pubspec.yaml')).writeAsString(
    jsonEncode(<String, Object?>{
      'name': name,
      'publish_to': 'none',
      'environment': <String, Object?>{'sdk': '^3.13.0'},
      'dependencies': dependencies,
      'dev_dependencies': <String, Object?>{
        'flutter_test': <String, Object?>{'sdk': 'flutter'},
      },
      'flutter': <String, Object?>{'uses-material-design': true},
    }),
  );

  final template = File(
    p.join(
      root,
      'tool',
      'e2e',
      fcm
          ? 'fcm_probe_main.dart.tmpl'
          : k09
          ? 'k09_probe_main.dart.tmpl'
          : biometric
          ? 'biometric_probe_main.dart.tmpl'
          : media || oversize
          ? 'media_probe_main.dart.tmpl'
          : 'device_probe_main.dart.tmpl',
    ),
  );
  final grantSeconds = _secondsOf(arguments, '--grant-seconds', 40);
  final revokeSeconds = _secondsOf(arguments, '--revoke-seconds', 40);
  final env = Platform.environment;
  final rendered = (await template.readAsString())
      .replaceAll('{{app_name}}', name)
      .replaceAll('@GRANT_SECONDS@', '$grantSeconds')
      .replaceAll('@REVOKE_SECONDS@', '$revokeSeconds')
      .replaceAll(
        '@ENDPOINT@',
        env['KILN_APPWRITE_ENDPOINT'] ?? 'https://appwrite.example/v1',
      )
      .replaceAll('@PROJECT@', env['KILN_APPWRITE_PROJECT'] ?? 'kiln')
      .replaceAll('@EMAIL@', env['KILN_PROBE_EMAIL'] ?? '')
      .replaceAll('@PASSWORD@', env['KILN_PROBE_PASSWORD'] ?? '');
  await File(
    p.join(fixture.path, 'lib', 'main.dart'),
  ).writeAsString(rendered);

  if (fcm) {
    await _applyFcmSetup(fixture, root);
  }

  if (!arguments.contains('--render-only')) {
    final pub = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: fixture.path,
      runInShell: Platform.isWindows,
    );
    stdout.write(pub.stdout);
    stderr.write(pub.stderr);
    if (pub.exitCode != 0) {
      exitCode = pub.exitCode;
      return;
    }
  }
  stdout.writeln('Device probe fixture: ${fixture.path}');
}

/// Reads `--flag <n>`, falling back to [fallback] when the flag is absent.
int _secondsOf(List<String> arguments, String flag, int fallback) {
  final index = arguments.indexOf(flag);
  if (index < 0 || index + 1 >= arguments.length) {
    return fallback;
  }
  return int.tryParse(arguments[index + 1]) ?? fallback;
}
/// Applies the manual Firebase steps the installer cannot do.
///
/// `appwrite_push` requires the app package to match `google-services.json`
/// and the Google Services Gradle plugin. The fixture therefore takes the
/// measurement id from the supplied file instead of a hardcoded package name.
Future<void> _applyFcmSetup(Directory fixture, String root) async {
  final source = File(p.join(root, '.dart_tool', 'k23', 'google-services.json'));
  if (!source.existsSync()) {
    throw StateError(
      'Put google-services.json at .dart_tool/k23/google-services.json.',
    );
  }
  final parsed =
      jsonDecode(await source.readAsString()) as Map<String, Object?>;
  final clients = (parsed['client'] as List<Object?>?) ?? const <Object?>[];
  final first = clients.isEmpty
      ? null
      : clients.first as Map<String, Object?>;
  final info =
      (first?['client_info'] as Map<String, Object?>?) ?? const <String, Object?>{};
  final packageName =
      (info['android_client_info'] as Map<String, Object?>?)?['package_name']
          as String?;
  if (packageName == null || packageName.isEmpty) {
    throw StateError('google-services.json has no android package_name.');
  }

  await source.copy(p.join(fixture.path, 'android', 'app', 'google-services.json'));

  // android/app/build.gradle(.kts): apply the plugin.
  for (final name in const <String>['build.gradle.kts', 'build.gradle']) {
    final file = File(p.join(fixture.path, 'android', 'app', name));
    if (!file.existsSync()) continue;
    var content = await file.readAsString();
    if (content.contains('com.google.gms.google-services')) continue;
    content = content.replaceFirst(
      RegExp(r'plugins\s*\{'),
      'plugins {\n    id("com.google.gms.google-services")',
    );
    await file.writeAsString(content);
    break;
  }
  // settings.gradle.kts: the app module applies the Google Services plugin, so
  // the settings file declares its version. Inserted after the Kotlin plugin
  // line; a version-placeholder regex here kept mangling the Android line.
  for (final name in const <String>['settings.gradle.kts', 'settings.gradle']) {
    final file = File(p.join(fixture.path, 'android', name));
    if (!file.existsSync()) continue;
    final content = await file.readAsString();
    if (!content.contains('com.google.gms.google-services')) {
      final marker = RegExp(
        r'^.*id\("org\.jetbrains\.kotlin\.android"\).*$',
        multiLine: true,
      );
      final match = marker.firstMatch(content);
      if (match != null) {
        final line = match.group(0)!;
        final declaration = line.trimRight().endsWith('apply false')
            ? line
            : '$line apply false';
        final added = content.replaceFirst(
          line,
          '$declaration\n'
          '    id("com.google.gms.google-services") version "4.4.2" apply false',
        );
        await file.writeAsString(added);
      }
    }
    break;
  }
  // android/build.gradle(.kts): declare the plugin version.
  for (final name in const <String>['build.gradle.kts', 'build.gradle']) {
    final file = File(p.join(fixture.path, 'android', name));
    if (!file.existsSync()) continue;
    var content = await file.readAsString();
    if (content.contains('google-services')) continue;
    if (name.endsWith('.kts')) {
      content = content.replaceFirst(
        RegExp(r'plugins\s*\{'),
        'plugins {\n    id("com.google.gms.google-services") version "4.4.2" apply false',
      );
    } else {
      content = content.replaceFirst(
        RegExp(r'buildscript\s*\{'),
        'buildscript {\n    dependencies {\n'
        "        classpath 'com.google.gms:google-services:4.4.2'\n    }",
      );
    }
    await file.writeAsString(content);
    break;
  }

  // applicationId must match the registered Firebase Android app.
  for (final name in const <String>['build.gradle.kts', 'build.gradle']) {
    final file = File(p.join(fixture.path, 'android', 'app', name));
    if (!file.existsSync()) continue;
    var content = await file.readAsString();
    content = content.replaceAll(
      RegExp(r'applicationId\s*=\s*"[^"]*"'),
      'applicationId = "$packageName"',
    );
    content = content.replaceAll(
      RegExp(r'applicationId\s+"[^"]*"'),
      'applicationId "$packageName"',
    );
    await file.writeAsString(content);
    break;
  }
  stdout.writeln('FCM setup applied for $packageName');
}
