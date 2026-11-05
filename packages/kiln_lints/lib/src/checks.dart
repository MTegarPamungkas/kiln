import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

/// Returns the path starting at the project's `lib/` directory, if present.
String libRelativePath(String filePath) {
  final normalized = filePath.replaceAll('\\', '/');
  final index = normalized.indexOf('/lib/');
  if (index >= 0) {
    return normalized.substring(index + 1);
  }
  if (normalized.startsWith('lib/')) {
    return normalized;
  }
  return normalized;
}

/// Whether [relativeLibPath] is under `lib/features/`.
bool isFeaturePath(String relativeLibPath) {
  return relativeLibPath == 'lib/features' ||
      relativeLibPath.startsWith('lib/features/');
}

/// Whether [relativeLibPath] is application/core wiring instead of a feature.
bool isAppPath(String relativeLibPath) {
  return relativeLibPath == 'lib/app' ||
      relativeLibPath.startsWith('lib/app/') ||
      relativeLibPath == 'lib/core' ||
      relativeLibPath.startsWith('lib/core/');
}

/// Extension id for a file under `lib/extensions/<id>/`, if any.
String? extensionIdForPath(String relativeLibPath) {
  final match = RegExp(
    r'^lib/extensions/([a-z][a-z0-9_]*)/',
  ).firstMatch(relativeLibPath);
  return match?.group(1);
}

/// Extension id referenced by an import, if the import targets an extension.
String? extensionIdForImport({
  required String relativeLibPath,
  required String importUri,
  required String packageName,
}) {
  final packagePrefix = 'package:$packageName/extensions/';
  if (importUri.startsWith(packagePrefix)) {
    final rest = importUri.substring(packagePrefix.length);
    final id = rest.split('/').first;
    return id.isEmpty ? null : id;
  }
  if (importUri.startsWith('package:') || importUri.startsWith('dart:')) {
    return null;
  }
  final resolved = p.posix.normalize(
    p.posix.join(p.posix.dirname(relativeLibPath), importUri),
  );
  final match = RegExp(
    r'(?:^|/)lib/extensions/([a-z][a-z0-9_]*)/',
  ).firstMatch(resolved);
  return match?.group(1);
}

/// Message for an extension importing another extension, or null when allowed.
String? crossExtensionImportMessage({
  required String filePath,
  required String importUri,
  required String packageName,
}) {
  final relative = libRelativePath(filePath);
  final ownId = extensionIdForPath(relative);
  if (ownId == null) {
    return null;
  }
  final targetId = extensionIdForImport(
    relativeLibPath: relative,
    importUri: importUri,
    packageName: packageName,
  );
  if (targetId == null || targetId == ownId) {
    return null;
  }
  return 'Extension "$ownId" imports "$targetId". '
      'Use a contract from kiln_core instead.';
}

/// Message when feature/app code imports an extension implementation.
String? extensionImportOutsideExtensionMessage({
  required String filePath,
  required String importUri,
  required String packageName,
}) {
  final relative = libRelativePath(filePath);
  if (!isFeaturePath(relative) && !isAppPath(relative)) {
    return null;
  }
  final targetId = extensionIdForImport(
    relativeLibPath: relative,
    importUri: importUri,
    packageName: packageName,
  );
  if (targetId == null) {
    return null;
  }
  return 'Do not import extension "$targetId" here. '
      'Read the contract from the Registry instead.';
}

const Set<String> defaultPluginPackages = <String>{
  'app_links',
  'cloud_firestore',
  'connectivity_plus',
  'dio',
  'firebase_auth',
  'firebase_core',
  'firebase_storage',
  'flutter_local_notifications',
  'flutter_secure_storage',
  'go_router',
  'google_sign_in',
  'image_picker',
  'local_auth',
  'path_provider',
  'permission_handler',
  'posthog_flutter',
  'sembast',
  'shared_preferences',
  'sign_in_with_apple',
  'supabase_flutter',
};

/// Plugin package name imported by [importUri], or null for non-package URIs.
String? pluginPackageOf(String importUri) {
  if (!importUri.startsWith('package:')) {
    return null;
  }
  final rest = importUri.substring('package:'.length);
  final slash = rest.indexOf('/');
  return slash <= 0 ? null : rest.substring(0, slash);
}

/// Message when a feature imports a plugin directly, or null when allowed.
String? pluginInFeatureMessage({
  required String filePath,
  required String importUri,
  Set<String> pluginPackages = defaultPluginPackages,
}) {
  if (!isFeaturePath(libRelativePath(filePath))) {
    return null;
  }
  final packageName = pluginPackageOf(importUri);
  if (packageName == null) {
    return null;
  }
  for (final plugin in pluginPackages) {
    if (packageName == plugin || packageName.startsWith('${plugin}_')) {
      return 'Feature code must not import plugin "$packageName". '
          'Use a contract from kiln_core instead.';
    }
  }
  return null;
}

/// Whether [source] or [filePath] marks a generated file.
bool isGeneratedSource({
  required String filePath,
  required String source,
}) {
  final normalized = filePath.replaceAll('\\', '/');
  return normalized.contains('/generated/') ||
      p.posix.basename(normalized) == 'extensions.g.dart' ||
      source.contains('GENERATED CODE - DO NOT MODIFY BY HAND');
}


/// Whether a catch clause swallows its error without handling it.
bool catchSwallowsErrors(CatchClause node) => node.body.statements.isEmpty;
