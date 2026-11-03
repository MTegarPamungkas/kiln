import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kiln_core/kiln_core.dart';

import '../env_describe.dart';
import '../env_schema.dart';

/// Debug screen for the active environment values.
final class EnvDebugPage extends StatelessWidget {
  const EnvDebugPage({
    super.key,
    required this.env,
    this.schema,
    this.flavor,
    this.replacement = '[redacted]',
  });

  final Env env;
  final EnvSchema? schema;
  final AppFlavor? flavor;
  final String replacement;

  bool get visible {
    final current = flavor;
    if (current != null) {
      return !current.isProduction;
    }
    return kDebugMode;
  }

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    final values = EnvDescribe(replacement: replacement).summarize(
      env,
      schema ?? EnvSchema.defaults,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Environment')),
      body: ListView(
        children: <Widget>[
          for (final entry in values.entries)
            ListTile(
              title: Text(entry.key),
              subtitle: Text(entry.value.isEmpty ? '(kosong)' : entry.value),
            ),
        ],
      ),
    );
  }
}
