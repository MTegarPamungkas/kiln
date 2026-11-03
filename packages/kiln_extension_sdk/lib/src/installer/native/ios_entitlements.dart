import 'ios_plist.dart';
import 'patch.dart';

const String kIosEntitlementsPath = 'ios/Runner/Runner.entitlements';

/// Adds one entitlement key.
final class IosEntitlementPatch implements Patch {
  const IosEntitlementPatch(this.key, this.value);

  final String key;
  final Object? value;

  @override
  String get id => 'ios.entitlements.$key';

  @override
  String get description => 'Add iOS entitlement $key';

  @override
  void apply(ProjectFiles files) {
    final content = ensurePlist(files.read(kIosEntitlementsPath));
    files.write(kIosEntitlementsPath, addPlistEntry(content, key, value));
  }

  @override
  void revert(ProjectFiles files) {
    final content = files.read(kIosEntitlementsPath);
    if (content == null) {
      return;
    }
    files.write(kIosEntitlementsPath, removePlistEntry(content, key));
  }
}

/// Adds one associated domain under the shared entitlements key.
final class IosAssociatedDomainPatch implements Patch {
  const IosAssociatedDomainPatch(this.domain);

  final String domain;

  String get _value => 'applinks:$domain';

  @override
  String get id => 'ios.associated_domain.$domain';

  @override
  String get description => 'Add iOS associated domain $domain';

  @override
  void apply(ProjectFiles files) {
    var content = ensurePlist(files.read(kIosEntitlementsPath));
    if (content.contains('<string>$_value</string>')) {
      return;
    }
    const key = 'com.apple.developer.associated-domains';
    final keyTag = '<key>$key</key>';
    final keyIndex = content.indexOf(keyTag);
    if (keyIndex < 0) {
      content = addPlistEntry(content, key, <String>[_value]);
      files.write(kIosEntitlementsPath, content);
      return;
    }

    var valueStart = keyIndex + keyTag.length;
    while (valueStart < content.length && content[valueStart].trim().isEmpty) {
      valueStart++;
    }
    final arrayEnd = elementEnd(content, valueStart);
    final closeIndex = content.lastIndexOf('</array>', arrayEnd);
    if (closeIndex < 0) {
      return;
    }
    content = content.replaceRange(
      closeIndex,
      closeIndex,
      '  <string>$_value</string>\n',
    );
    files.write(kIosEntitlementsPath, content);
  }

  @override
  void revert(ProjectFiles files) {
    final content = files.read(kIosEntitlementsPath);
    if (content == null) {
      return;
    }
    files.write(
      kIosEntitlementsPath,
      content.replaceAll('<string>$_value</string>', ''),
    );
  }
}
