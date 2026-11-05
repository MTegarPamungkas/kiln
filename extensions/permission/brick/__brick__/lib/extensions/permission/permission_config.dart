import 'package:kiln_core/kiln_core.dart';

/// Runtime permission settings from the install prompts.
///
/// Only the kinds selected at install time are active. Rationale and settings
/// copy belong to the application; the SDK returns statuses and flow results.
final class PermissionConfig {
  const PermissionConfig({required this.activeKinds});

  static const defaults = PermissionConfig(
    activeKinds: <PermissionKind>{
{{#kinds}}
      PermissionKind.{{.}},
{{/kinds}}
    },
  );

  final Set<PermissionKind> activeKinds;
}
