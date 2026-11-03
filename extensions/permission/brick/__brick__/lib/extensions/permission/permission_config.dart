import 'package:kiln_core/kiln_core.dart';

/// Runtime permission settings from the install prompts.
final class PermissionConfig {
  const PermissionConfig({
    required this.activeKinds,
    this.rationaleTitle = 'Izin diperlukan',
    this.rationaleMessage =
        'Aplikasi membutuhkan izin ini untuk melanjutkan.',
  });

  static const defaults = PermissionConfig(
    activeKinds: <PermissionKind>{
{{#kinds}}
      PermissionKind.{{.}},
{{/kinds}}
    },
  );

  final Set<PermissionKind> activeKinds;
  final String rationaleTitle;
  final String rationaleMessage;
}
