import 'dart:io';

import 'package:kiln_cli/kiln_cli.dart';
import 'package:path/path.dart' as p;

Directory get repoRoot => Directory.current.parent.parent;

String get corePath =>
    p.join(repoRoot.path, 'packages', 'kiln_core').replaceAll('\\', '/');

final class CapturedLogger {
  CapturedLogger() {
    logger = KilnLogger(out: _out.add, err: _err.add);
  }

  final List<String> _out = <String>[];
  final List<String> _err = <String>[];
  late final KilnLogger logger;

  List<String> get out => List<String>.unmodifiable(_out);
  List<String> get err => List<String>.unmodifiable(_err);

  void clear() {
    _out.clear();
    _err.clear();
  }
}

final class FakeProcessRunner extends ProcessRunner {
  FakeProcessRunner(this.handler);

  final Future<ProcessResult> Function(
    String executable,
    List<String> arguments,
    String? workingDirectory,
  )
  handler;

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool runInShell = false,
    Map<String, String>? environment,
  }) {
    return handler(executable, arguments, workingDirectory);
  }
}

Future<Directory> createTempProject({String name = 'test_app'}) async {
  final root = await Directory.systemTemp.createTemp('kiln_cli_');
  await File(p.join(root.path, 'pubspec.yaml')).writeAsString('''
name: $name
description: Test project.
publish_to: none
version: 0.1.0

environment:
  sdk: ^3.13.0

dependencies:
  kiln_core:
    path: $corePath
''');
  await File(p.join(root.path, 'kiln.yaml')).writeAsString('''
kiln: ">=0.1.0 <0.2.0"
core: ^0.1.0
project:
  name: $name
  org: com.example
  platforms: [android, ios, web]
state: none
extensions: {}
''');
  await Directory(p.join(root.path, 'lib')).create(recursive: true);
  await File(p.join(root.path, 'lib', 'main.dart'))
      .writeAsString('void main() {}\n');
  await _writeAndroidManifest(root);
  return root;
}

Future<void> _writeAndroidManifest(Directory root) async {
  final manifest = File(
    p.join(root.path, 'android', 'app', 'src', 'main', 'AndroidManifest.xml'),
  );
  await manifest.parent.create(recursive: true);
  await manifest.writeAsString('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="test_app">
        <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
''');
}

KilnCommandRunner buildTestRunner({
  required Directory cwd,
  required CapturedLogger captured,
  ProcessRunner? processRunner,
  Prompter? prompter,
}) {
  return buildKilnCommandRunner(
    cwd: cwd,
    logger: captured.logger,
    prompter:
        prompter ??
        Prompter(
          assumeYes: true,
          interactive: false,
          readLine: (_) => null,
          write: (_) {},
        ),
    processRunner: processRunner ?? const ProcessRunner(),
    fileSystem: const LocalFileSystem(),
    globalConfig: const GlobalConfig(),
  );
}
