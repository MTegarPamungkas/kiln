import 'dart:io';

import 'package:path/path.dart' as p;

import 'patch.dart';

const List<String> _gradleCandidates = <String>[
  'android/app/build.gradle.kts',
  'android/app/build.gradle',
];

String? _gradleFile(ProjectFiles files) {
  for (final candidate in _gradleCandidates) {
    if (files.exists(candidate)) {
      return candidate;
    }
  }
  return null;
}

/// Raises the Android minSdk used for the application.
final class AndroidGradleMinSdkPatch implements Patch {
  const AndroidGradleMinSdkPatch(this.minSdk);

  final int minSdk;

  @override
  String get id => 'android.min_sdk';

  @override
  String get description => 'Set Android minSdk to $minSdk';

  @override
  void apply(ProjectFiles files) {
    final path = _gradleFile(files);
    if (path == null) {
      return;
    }
    var content = files.read(path);
    if (content == null || content.contains('// kiln:min_sdk')) {
      return;
    }

    final kotlin = RegExp(r'minSdk\s*=\s*([^\n]+)');
    final groovy = RegExp(r'minSdkVersion\s+([^\n]+)');
    final match = kotlin.firstMatch(content) ?? groovy.firstMatch(content);
    if (match != null) {
      final original = match.group(1)!.trim();
      final replacement = content
          .substring(match.start, match.end)
          .replaceFirst(
            match.group(1)!,
            '$minSdk // kiln:min_sdk from $original',
          );
      content = content.replaceRange(match.start, match.end, replacement);
      files.write(path, content);
      return;
    }

    final defaultConfig = RegExp(r'defaultConfig\s*\{');
    final configMatch = defaultConfig.firstMatch(content);
    if (configMatch == null) {
      return;
    }
    final insertAt = configMatch.end;
    final line = path.endsWith('.gradle')
        ? '\n        minSdkVersion $minSdk // kiln:min_sdk'
        : '\n        minSdk = $minSdk // kiln:min_sdk';
    files.write(path, content.replaceRange(insertAt, insertAt, line));
  }

  @override
  void revert(ProjectFiles files) {
    final path = _gradleFile(files);
    if (path == null) {
      return;
    }
    final content = files.read(path);
    if (content == null) {
      return;
    }
    final isGroovy = path.endsWith('.gradle');
    final marker = RegExp(
      r'minSdk(?:Version)?\s*(?:=\s*)?\d+\s*// kiln:min_sdk(?: from ([^\n]+))?',
    );
    files.write(
      path,
      content.replaceAllMapped(marker, (match) {
        final original = match.group(1)?.trim();
        if (original == null) {
          return isGroovy
              ? 'minSdkVersion flutter.minSdkVersion'
              : 'minSdk = flutter.minSdkVersion';
        }
        return isGroovy ? 'minSdkVersion $original' : 'minSdk = $original';
      }),
    );
  }
}

/// Switches MainActivity to FlutterFragmentActivity.
final class AndroidActivityPatch implements Patch {
  const AndroidActivityPatch(this.activity);

  final String activity;

  @override
  String get id => 'android.activity';

  @override
  String get description => 'Use $activity as the Android host activity';

  String? _mainActivity(ProjectFiles files) {
    final roots = <Directory>[
      Directory(
        p.join(
          files.projectRoot.path,
          'android',
          'app',
          'src',
          'main',
          'kotlin',
        ),
      ),
      Directory(
        p.join(files.projectRoot.path, 'android', 'app', 'src', 'main', 'java'),
      ),
    ];
    for (final root in roots) {
      if (!root.existsSync()) {
        continue;
      }
      for (final entity in root.listSync(recursive: true)) {
        if (entity is File) {
          final name = p.basename(entity.path);
          if (name == 'MainActivity.kt' || name == 'MainActivity.java') {
            return p.relative(entity.path, from: files.projectRoot.path);
          }
        }
      }
    }
    return null;
  }

  @override
  void apply(ProjectFiles files) {
    final path = _mainActivity(files);
    if (path == null) {
      return;
    }
    final content = files.read(path);
    if (content == null || content.contains(activity)) {
      return;
    }
    var updated = content;
    if (updated.contains(
      'import io.flutter.embedding.android.FlutterActivity',
    )) {
      updated = updated.replaceFirst(
        'import io.flutter.embedding.android.FlutterActivity',
        'import io.flutter.embedding.android.$activity',
      );
    } else {
      updated = updated.replaceFirst(
        'package ',
        'import io.flutter.embedding.android.$activity\n\npackage ',
      );
    }
    updated = updated
        .replaceFirst(': FlutterActivity()', ': $activity()')
        .replaceFirst('extends FlutterActivity', 'extends $activity');
    files.write(path, updated);
  }

  @override
  void revert(ProjectFiles files) {
    final path = _mainActivity(files);
    if (path == null) {
      return;
    }
    final content = files.read(path);
    if (content == null) {
      return;
    }
    files.write(path, content.replaceAll(activity, 'FlutterActivity'));
  }
}

/// Enables core library desugaring so plugins using newer java.time APIs
/// (for example `flutter_local_notifications`) can build on Android.
final class AndroidGradleDesugaringPatch implements Patch {
  const AndroidGradleDesugaringPatch();

  static const _marker = '// kiln:desugar';
  static const _desugarVersion = '2.1.5';

  @override
  String get id => 'android.desugar';

  @override
  String get description => 'Enable core library desugaring';

  @override
  void apply(ProjectFiles files) {
    final path = _gradleFile(files);
    if (path == null) {
      return;
    }
    var content = files.read(path);
    if (content == null || content.contains(_marker)) {
      return;
    }
    final groovy = path.endsWith('.gradle');

    final compileOptions = RegExp(r'compileOptions\s*\{').firstMatch(content);
    if (compileOptions != null) {
      final flag = groovy
          ? '        coreLibraryDesugaringEnabled true $_marker'
          : '        isCoreLibraryDesugaringEnabled = true $_marker';
      content = content.replaceRange(
        compileOptions.end,
        compileOptions.end,
        '\n$flag',
      );
    } else {
      final android = RegExp(r'android\s*\{').firstMatch(content);
      if (android == null) {
        return;
      }
      final block = groovy
          ? '\n    compileOptions {\n'
                '        sourceCompatibility JavaVersion.VERSION_17\n'
                '        targetCompatibility JavaVersion.VERSION_17\n'
                '        coreLibraryDesugaringEnabled true $_marker\n'
                '    }'
          : '\n    compileOptions {\n'
                '        sourceCompatibility = JavaVersion.VERSION_17\n'
                '        targetCompatibility = JavaVersion.VERSION_17\n'
                '        isCoreLibraryDesugaringEnabled = true $_marker\n'
                '    }';
      content = content.replaceRange(android.end, android.end, block);
    }

    final dependency = groovy
        ? "    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:"
              "$_desugarVersion' $_marker"
        : '    coreLibraryDesugaring('
              '"com.android.tools:desugar_jdk_libs:$_desugarVersion") $_marker';
    final dependencies = RegExp(r'dependencies\s*\{').firstMatch(content);
    if (dependencies != null) {
      content = content.replaceRange(
        dependencies.end,
        dependencies.end,
        '\n$dependency',
      );
    } else {
      content = '${content.trimRight()}\n\ndependencies {\n$dependency\n}\n';
    }
    files.write(path, content);
  }

  @override
  void revert(ProjectFiles files) {
    final path = _gradleFile(files);
    if (path == null) {
      return;
    }
    final content = files.read(path);
    if (content == null || !content.contains(_marker)) {
      return;
    }
    final lines = content
        .split('\n')
        .where((line) => !line.contains(_marker))
        .join('\n');
    files.write(path, lines);
  }
}
