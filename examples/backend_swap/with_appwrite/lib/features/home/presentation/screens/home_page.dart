import 'package:flutter/material.dart';
import 'package:with_appwrite/app/registry_scope.dart';
import 'package:with_appwrite/core/l10n/core_copy.dart';

/// Starting page owned by the application.
///
/// Replace this feature with your first real one; the SDK only wires the
/// registry. Keep the layer folders: `domain`, `data`, `presentation`.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final copy = RegistryScope.read<CoreCopy>(context);
    return Scaffold(
      appBar: AppBar(title: Text(copy.appTitle(context))),
      body: const Center(
        child: Icon(Icons.local_fire_department_rounded, size: 48),
      ),
    );
  }
}
