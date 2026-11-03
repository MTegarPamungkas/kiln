import '../../manifest/platform_setup.dart';
import 'patch.dart';

const String kAndroidManifestPath = 'android/app/src/main/AndroidManifest.xml';

/// Adds one `<uses-permission>` element.
final class AndroidPermissionPatch implements Patch {
  const AndroidPermissionPatch(this.permission);

  final String permission;

  String get _shortName => permission.startsWith('android.permission.')
      ? permission.substring('android.permission.'.length)
      : permission;

  @override
  String get id => 'android.permission.$_shortName';

  @override
  String get description => 'Add Android permission $permission';

  @override
  void apply(ProjectFiles files) {
    final content = files.read(kAndroidManifestPath);
    if (content == null || content.contains(permission)) {
      return;
    }
    final element = '    <uses-permission android:name="$permission"/>\n';
    final updated = content.replaceFirst('</manifest>', '$element</manifest>');
    files.write(kAndroidManifestPath, updated);
  }

  @override
  void revert(ProjectFiles files) {
    final content = files.read(kAndroidManifestPath);
    if (content == null) {
      return;
    }
    final pattern = RegExp(
      r'\s*<uses-permission\s+android:name="' +
          RegExp.escape(permission) +
          r'"\s*/>',
    );
    files.write(kAndroidManifestPath, content.replaceAll(pattern, ''));
  }
}

/// Adds a custom URL scheme intent filter to the main activity.
final class AndroidUrlSchemePatch implements Patch {
  const AndroidUrlSchemePatch(this.scheme);

  final String scheme;

  @override
  String get id => 'android.url_scheme.$scheme';

  @override
  String get description => 'Add Android URL scheme $scheme';

  @override
  void apply(ProjectFiles files) {
    final content = files.read(kAndroidManifestPath);
    if (content == null ||
        content.contains('android:scheme="$scheme"') ||
        !content.contains('</activity>')) {
      return;
    }
    final block =
        '''
    <!-- kiln:$id -->
    <intent-filter>
      <action android:name="android.intent.action.VIEW"/>
      <category android:name="android.intent.category.DEFAULT"/>
      <category android:name="android.intent.category.BROWSABLE"/>
      <data android:scheme="$scheme"/>
    </intent-filter>
''';
    files.write(
      kAndroidManifestPath,
      content.replaceFirst('</activity>', '$block    </activity>'),
    );
  }

  @override
  void revert(ProjectFiles files) {
    final content = files.read(kAndroidManifestPath);
    if (content == null) {
      return;
    }
    final pattern = RegExp(
      r'\s*<!-- kiln:android\.url_scheme\.' +
          RegExp.escape(scheme) +
          r' -->\s*<intent-filter>.*?</intent-filter>',
      dotAll: true,
    );
    files.write(kAndroidManifestPath, content.replaceAll(pattern, ''));
  }
}

/// Adds an App Links intent filter with verification.
final class AndroidAppLinkPatch implements Patch {
  const AndroidAppLinkPatch(this.host, {this.pathPrefixes = const <String>[]});

  final String host;
  final List<String> pathPrefixes;

  @override
  String get id => 'android.app_link.$host';

  @override
  String get description => 'Add Android App Link for $host';

  @override
  void apply(ProjectFiles files) {
    final content = files.read(kAndroidManifestPath);
    if (content == null ||
        content.contains('android:host="$host"') ||
        !content.contains('</activity>')) {
      return;
    }
    final data = pathPrefixes.isEmpty
        ? '      <data android:scheme="https" android:host="$host"/>\n'
        : pathPrefixes
              .map(
                (prefix) =>
                    '      <data android:scheme="https" android:host="$host" android:pathPrefix="$prefix"/>\n',
              )
              .join();
    final block =
        '''
    <!-- kiln:$id -->
    <intent-filter android:autoVerify="true">
      <action android:name="android.intent.action.VIEW"/>
      <category android:name="android.intent.category.DEFAULT"/>
      <category android:name="android.intent.category.BROWSABLE"/>
$data    </intent-filter>
''';
    files.write(
      kAndroidManifestPath,
      content.replaceFirst('</activity>', '$block    </activity>'),
    );
  }

  @override
  void revert(ProjectFiles files) {
    final content = files.read(kAndroidManifestPath);
    if (content == null) {
      return;
    }
    final pattern = RegExp(
      r'\s*<!-- kiln:android\.app_link\.' +
          RegExp.escape(host) +
          r' -->\s*<intent-filter[^>]*>.*?</intent-filter>',
      dotAll: true,
    );
    files.write(kAndroidManifestPath, content.replaceAll(pattern, ''));
  }
}

/// Adds a `<receiver>` element under the application element.
final class AndroidReceiverPatch implements Patch {
  const AndroidReceiverPatch(this.receiver);

  final AndroidReceiverSetup receiver;

  @override
  String get id => 'android.receiver.${receiver.name}';

  @override
  String get description => 'Add Android receiver ${receiver.name}';

  @override
  void apply(ProjectFiles files) {
    final content = files.read(kAndroidManifestPath);
    if (content == null ||
        content.contains('android:name="${receiver.name}"') ||
        !content.contains('</application>')) {
      return;
    }
    final actions = receiver.actions
        .map((action) => '        <action android:name="$action"/>\n')
        .join();
    final intentFilter = receiver.actions.isEmpty
        ? ''
        : '\n      <intent-filter>\n$actions      </intent-filter>';
    final block =
        '''
    <!-- kiln:$id -->
    <receiver
      android:name="${receiver.name}"
      android:exported="${receiver.exported}">$intentFilter
    </receiver>
''';
    files.write(
      kAndroidManifestPath,
      content.replaceFirst('</application>', '$block    </application>'),
    );
  }

  @override
  void revert(ProjectFiles files) {
    final content = files.read(kAndroidManifestPath);
    if (content == null) {
      return;
    }
    final pattern = RegExp(
      r'\s*<!-- kiln:android\.receiver\.' +
          RegExp.escape(receiver.name) +
          r' -->\s*<receiver[\s\S]*?</receiver>',
      dotAll: true,
    );
    files.write(kAndroidManifestPath, content.replaceAll(pattern, ''));
  }
}

/// Sets `android:allowBackup` on the application element.
final class AndroidAllowBackupPatch implements Patch {
  const AndroidAllowBackupPatch(this.allowBackup);

  final bool allowBackup;

  @override
  String get id => 'android.allow_backup';

  @override
  String get description => 'Set Android allowBackup to $allowBackup';

  @override
  void apply(ProjectFiles files) {
    final content = files.read(kAndroidManifestPath);
    if (content == null) {
      return;
    }
    final application = RegExp(r'<application\b[^>]*>');
    final match = application.firstMatch(content);
    if (match == null) {
      return;
    }
    final tag = match.group(0)!;
    final value = allowBackup ? 'true' : 'false';
    final updatedTag = tag.contains('android:allowBackup=')
        ? tag.replaceFirst(
            RegExp(r'android:allowBackup="[^"]*"'),
            'android:allowBackup="$value"',
          )
        : tag.replaceFirst('>', ' android:allowBackup="$value">');
    files.write(
      kAndroidManifestPath,
      content.replaceRange(match.start, match.end, updatedTag),
    );
  }

  @override
  void revert(ProjectFiles files) {
    final content = files.read(kAndroidManifestPath);
    if (content == null) {
      return;
    }
    files.write(
      kAndroidManifestPath,
      content.replaceFirst(RegExp(r'\s*android:allowBackup="[^"]*"'), ''),
    );
  }
}
