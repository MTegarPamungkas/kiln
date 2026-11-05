import 'package:flutter/material.dart';
import 'package:kiln_core/kiln_core.dart';

import 'app_shell.dart';
import 'registry_scope.dart';

/// Root widget that makes the bootstrap [Registry] available to the tree.
class KilnApp extends StatelessWidget {
  const KilnApp({required this.registry, super.key});

  final Registry registry;

  @override
  Widget build(BuildContext context) {
    return RegistryScope(
      registry: registry,
      child: const AppShell(),
    );
  }
}
