import 'patch.dart';

const String kIosPodfilePath = 'ios/Podfile';

/// Enables one `PERMISSION_*` flag required by permission_handler.
final class IosPodfilePermissionPatch implements Patch {
  const IosPodfilePermissionPatch(this.permission);

  final String permission;

  String get _flag => 'PERMISSION_${permission.toUpperCase()} = 1';

  @override
  String get id => 'ios.podfile_permission.${permission.toLowerCase()}';

  @override
  String get description => 'Enable Podfile flag $_flag';

  @override
  void apply(ProjectFiles files) {
    final content = files.read(kIosPodfilePath);
    if (content == null || content.contains(_flag)) {
      return;
    }
    final platform = RegExp(r'^platform :ios.*$', multiLine: true);
    final match = platform.firstMatch(content);
    if (match == null) {
      files.write(kIosPodfilePath, '$_flag\n$content');
      return;
    }
    files.write(
      kIosPodfilePath,
      content.replaceRange(match.end, match.end, '\n$_flag'),
    );
  }

  @override
  void revert(ProjectFiles files) {
    final content = files.read(kIosPodfilePath);
    if (content == null) {
      return;
    }
    files.write(
      kIosPodfilePath,
      content.replaceAll(RegExp(r'\n?PERMISSION_[A-Z_]+ = 1'), ''),
    );
  }
}
