{{#minimal}}
import 'package:flutter/material.dart';

import '../../app/registry_scope.dart';
import '../../core/l10n/core_copy.dart';

/// Starting page owned by the application.
///
/// Replace it with the first feature screen; the SDK only wires the registry.
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
{{/minimal}}
{{^minimal}}
// The starter template renders its own starter page from AppHome.
{{/minimal}}
