import 'dart:io';

import 'package:path/path.dart' as p;

import '../../manifest/extension_manifest.dart';
import '../../manifest/platform_setup.dart';
import 'android_gradle.dart';
import 'android_project.dart';
import 'ios_app_delegate.dart';
import 'ios_entitlements.dart';
import 'ios_plist.dart';
import 'ios_podfile.dart';
import 'macos_entitlements.dart';
import 'patch.dart';
import 'web_index_html.dart';

/// Patches plus the resulting file contents.
final class NativeSetupResult {
  const NativeSetupResult({required this.patches, required this.changes});

  final List<Patch> patches;
  final Map<String, String?> changes;
}

/// Applies the native part of an extension manifest.
final class NativeSetup {
  const NativeSetup();

  /// Returns the patches for [manifest].
  ///
  /// [answers] are the resolved prompt answers; conditional entries apply only
  /// when their `when` map matches.
  List<Patch> patchesFor(
    ExtensionManifest manifest,
    Directory projectRoot, {
    Map<String, Object?> answers = const <String, Object?>{},
  }) {
    final setup = manifest.platformSetup;
    final patches = <Patch>[];
    _append(
      android: setup.android,
      ios: setup.ios,
      macos: setup.macos,
      web: setup.web,
      platforms: setup.platforms,
      projectRoot: projectRoot,
      extensionId: manifest.id,
      patches: patches,
    );
    for (final conditional in setup.conditionals) {
      if (!conditional.matches(answers)) {
        continue;
      }
      _append(
        android: conditional.android,
        ios: conditional.ios,
        macos: conditional.macos,
        web: conditional.web,
        platforms: setup.platforms,
        projectRoot: projectRoot,
        extensionId: manifest.id,
        patches: patches,
      );
    }

    final unique = <Patch>[];
    final seen = <String>{};
    for (final patch in patches) {
      if (seen.add(patch.id)) {
        unique.add(patch);
      }
    }
    return List<Patch>.unmodifiable(unique);
  }

  void _append({
    required AndroidSetup android,
    required IosSetup ios,
    required MacosSetup macos,
    required WebSetup web,
    required List<String> platforms,
    required Directory projectRoot,
    required String extensionId,
    required List<Patch> patches,
  }) {
    bool supports(String platform) =>
        platforms.isEmpty || platforms.contains(platform);

    final androidDir = Directory(p.join(projectRoot.path, 'android'));
    if (androidDir.existsSync() && supports('android')) {
      for (final permission in android.permissions) {
        patches.add(AndroidPermissionPatch(permission));
      }
      for (final scheme in android.urlSchemes) {
        patches.add(AndroidUrlSchemePatch(scheme));
      }
      for (final host in android.appLinkHosts) {
        patches.add(
          AndroidAppLinkPatch(host, pathPrefixes: android.appLinkPathPrefixes),
        );
      }
      for (final receiver in android.receivers) {
        patches.add(AndroidReceiverPatch(receiver));
      }
      final allowBackup = android.allowBackup;
      if (allowBackup != null) {
        patches.add(AndroidAllowBackupPatch(allowBackup));
      }
      final activity = android.activity;
      if (activity != null) {
        patches.add(AndroidActivityPatch(activity));
      }
      final minSdk = android.minSdk;
      if (minSdk != null) {
        patches.add(AndroidGradleMinSdkPatch(minSdk));
      }
      final compileSdk = android.compileSdk;
      if (compileSdk != null) {
        patches.add(AndroidGradleCompileSdkPatch(compileSdk));
      }
    }

    final iosDir = Directory(p.join(projectRoot.path, 'ios'));
    if (iosDir.existsSync() && supports('ios')) {
      for (final entry in ios.plist.entries) {
        patches.add(IosPlistKeyPatch(entry.key, entry.value));
      }
      for (final scheme in ios.urlSchemes) {
        patches.add(IosUrlSchemePatch(scheme));
      }
      for (final permission in ios.podfilePermissions) {
        patches.add(IosPodfilePermissionPatch(permission));
      }
      for (final entry in ios.entitlements.entries) {
        patches.add(IosEntitlementPatch(entry.key, entry.value));
      }
      for (final domain in ios.associatedDomains) {
        patches.add(IosAssociatedDomainPatch(domain));
      }
      if (ios.urlSchemes.isNotEmpty) {
        patches.add(const IosAppDelegatePatch());
      }
    }

    final macosDir = Directory(p.join(projectRoot.path, 'macos'));
    if (macosDir.existsSync() && supports('macos')) {
      for (final entry in macos.entitlements.entries) {
        patches.add(MacosEntitlementPatch(entry.key, entry.value));
      }
      for (final scheme in macos.urlSchemes) {
        patches.add(MacosUrlSchemePatch(scheme));
      }
    }

    final webIndex = File(p.join(projectRoot.path, kWebIndexPath));
    if (webIndex.existsSync() && supports('web') && web.indexHtml) {
      patches.add(WebIndexMetaPatch(extensionId));
    }
  }

  NativeSetupResult plan({
    required Directory projectRoot,
    required ExtensionManifest manifest,
    Map<String, Object?> answers = const <String, Object?>{},
    ProjectFiles? files,
  }) {
    final patches = patchesFor(manifest, projectRoot, answers: answers);
    final projectFiles = files ?? ProjectFiles(projectRoot);
    for (final patch in patches) {
      patch.apply(projectFiles);
    }
    return NativeSetupResult(patches: patches, changes: projectFiles.changes);
  }

  NativeSetupResult revert({
    required List<Patch> patches,
    required Directory projectRoot,
    ProjectFiles? files,
  }) {
    final projectFiles = files ?? ProjectFiles(projectRoot);
    for (final patch in patches.reversed) {
      patch.revert(projectFiles);
    }
    return NativeSetupResult(patches: patches, changes: projectFiles.changes);
  }
}
