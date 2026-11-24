import 'package:analyzer/analysis_rule/rule_context.dart';

final RegExp _pubspecNamePattern = RegExp(
  r'^\s*name\s*:\s*([a-zA-Z0-9_]+)\s*$',
  multiLine: true,
);

/// Resolves the Dart package name for [context], or an empty string if unknown.
String packageNameForContext(RuleContext context) {
  final uri = context.libraryElement?.uri;
  if (uri != null && uri.scheme == 'package' && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.first;
  }
  final pubspecFile = context.package?.root.getFile('pubspec.yaml');
  if (pubspecFile != null && pubspecFile.exists) {
    try {
      final match = _pubspecNamePattern.firstMatch(
        pubspecFile.readAsStringSync(),
      );
      if (match != null) {
        return match.group(1)!;
      }
    } catch (_) {
      // Ignore unreadable pubspec files during analysis.
    }
  }
  return '';
}
