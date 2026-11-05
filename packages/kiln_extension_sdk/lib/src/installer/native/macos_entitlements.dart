import 'ios_plist.dart';
import 'patch.dart';

const List<String> kMacosEntitlementsPaths = <String>[
  'macos/Runner/DebugProfile.entitlements',
  'macos/Runner/Release.entitlements',
];

/// Adds one entitlement key to both macOS entitlement files.
final class MacosEntitlementPatch implements Patch {
  const MacosEntitlementPatch(this.key, this.value);

  final String key;
  final Object? value;

  @override
  String get id => 'macos.entitlements.$key';

  @override
  String get description => 'Add macOS entitlement $key';

  @override
  void apply(ProjectFiles files) {
    for (final path in kMacosEntitlementsPaths) {
      final content = files.read(path);
      if (content == null) {
        continue;
      }
      files.write(path, addPlistEntry(content, key, value));
    }
  }

  @override
  void revert(ProjectFiles files) {
    for (final path in kMacosEntitlementsPaths) {
      final content = files.read(path);
      if (content == null) {
        continue;
      }
      files.write(path, removePlistEntry(content, key));
    }
  }
}
