import 'dart:convert';
import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

/// Renders the current Appwrite/Dio/router sources into a disposable device app.
/// Credentials come from the loopback fixture at runtime, never generated code.
Future<void> main(List<String> arguments) async {
  final root = Directory.current.path;
  final routing = arguments.contains('--routing');
  final fixture = Directory(
    p.join(
      root,
      '.dart_tool',
      routing ? 'push_routing_platform' : 'appwrite_platform',
    ),
  );
  await fixture.create(recursive: true);
  if (!Directory(p.join(fixture.path, 'android')).existsSync()) {
    final created = await Process.run('flutter', [
      'create',
      '--platforms=android,web',
      '--project-name=e2e_appwrite',
      routing ? '--org=dev.kiln.routing' : '--org=dev.kiln',
      fixture.path,
    ], runInShell: Platform.isWindows);
    if (created.exitCode != 0) throw StateError('Flutter scaffold failed.');
  }
  final dependencies = <String, Object?>{
    'flutter': {'sdk': 'flutter'},
    'kiln_core': {
      'path': p.join(root, 'packages', 'kiln_core').replaceAll('\\', '/'),
    },
  };
  final push = arguments.contains('--push');
  final services = arguments.contains('--services') || push || routing;
  for (final id in [
    'appwrite',
    'dio',
    'go_router',
    if (services) 'appwrite_push_native',
  ]) {
    final source = Directory(p.join(root, 'extensions', id));
    final manifest = ExtensionManifest.parse(
      File(p.join(source.path, 'extension.yaml')).readAsStringSync(),
    );
    final bundle = createBundle(Directory(p.join(source.path, 'brick')));
    final native = const NativeSetup().plan(
      projectRoot: fixture,
      manifest: manifest,
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
        project: const {'name': 'e2e_appwrite'},
        answers: {
          'endpoint':
              Platform.environment['KILN_APPWRITE_ENDPOINT'] ??
              'https://cloud.appwrite.io/v1',
          'project_id':
              Platform.environment['KILN_APPWRITE_PROJECT'] ?? 'kiln_demo',
          'database_id': 'kiln',
          'bucket_id': 'kiln_files',
          'base_url': 'http://127.0.0.1:8767',
        },
      ),
    );
    for (final file in files.where(
      (file) =>
          file.relativePath.startsWith('lib/') ||
          file.relativePath.startsWith('web/'),
    )) {
      final target = File(p.join(fixture.path, file.relativePath));
      await target.parent.create(recursive: true);
      await target.writeAsBytes(file.bytes);
    }
  }
  await File(p.join(fixture.path, 'pubspec.yaml')).writeAsString(
    jsonEncode({
      'name': 'e2e_appwrite',
      'publish_to': 'none',
      'environment': {'sdk': '^3.13.0'},
      'dependencies': dependencies,
      'dev_dependencies': {
        'flutter_test': {'sdk': 'flutter'},
      },
      'flutter': {'uses-material-design': true},
    }),
  );
  final route = File(p.join(fixture.path, 'lib', 'app', 'app_route.dart'));
  await route.parent.create(recursive: true);
  await File(
    p.join(
      root,
      'bricks',
      'app_basic',
      '__brick__',
      'lib',
      'app',
      'app_route.dart',
    ),
  ).copy(route.path);
  if (routing) {
    final manifest = File(
      p.join(
        fixture.path,
        'android',
        'app',
        'src',
        'main',
        'AndroidManifest.xml',
      ),
    );
    var xml = await manifest.readAsString();
    xml = xml.replaceFirst(
      'android:label="e2e_appwrite"',
      'android:label="Kiln Push Routing"',
    );
    if (!xml.contains('com.linusu.flutter_web_auth_2.CallbackActivity')) {
      xml = xml.replaceFirst(
        '</application>',
        '<activity android:name="com.linusu.flutter_web_auth_2.CallbackActivity" android:exported="true"><intent-filter><action android:name="android.intent.action.VIEW"/><category android:name="android.intent.category.DEFAULT"/><category android:name="android.intent.category.BROWSABLE"/><data android:scheme="appwrite-callback-6afebe9d000e9c351b3e"/></intent-filter></activity></application>',
      );
    }
    await manifest.writeAsString(xml);
  }
  final probeTemplate = File(
    p.join(
      root,
      'tool',
      'e2e',
      routing
          ? 'appwrite_push_routing_probe.dart.template'
          : push
          ? 'appwrite_push_probe.dart.template'
          : services
          ? 'appwrite_services_probe.dart.template'
          : 'platform_probe.dart.template',
    ),
  );
  await File(p.join(fixture.path, 'lib', 'main.dart'))
      .writeAsString(await probeTemplate.readAsString());
  final debugManifest = File(
    p.join(
      fixture.path,
      'android',
      'app',
      'src',
      'debug',
      'AndroidManifest.xml',
    ),
  );
  var xml = debugManifest.readAsStringSync();
  if (!xml.contains('usesCleartextTraffic')) {
    xml = xml.replaceFirst(
      '</manifest>',
      '    <application android:usesCleartextTraffic="true" />\n</manifest>',
    );
    await debugManifest.writeAsString(xml);
  }
  stdout.writeln('Rendered platform probe: ${fixture.path}');
}
