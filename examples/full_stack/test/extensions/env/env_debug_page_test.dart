import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/env/build_env.dart';
import 'package:full_stack/extensions/env/env_schema.dart';
import 'package:full_stack/extensions/env/widgets/env_debug_page.dart';

final _env = BuildEnv(
  schema: EnvSchema.defaults,
  values: const <String, String>{
    'api_base_url': 'https://api.kiln.dev',
    'api_key': 'super-secret',
  },
);

void main() {
  testWidgets('shows values and masks secrets in development', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EnvDebugPage(
          env: _env,
          schema: EnvSchema.defaults,
          flavor: AppFlavor.development,
        ),
      ),
    );

    expect(find.text('api_base_url'), findsOneWidget);
    expect(find.text('https://api.kiln.dev'), findsOneWidget);
    expect(find.text('super-secret'), findsNothing);
    expect(find.text('[redacted]'), findsOneWidget);
  });

  testWidgets('is hidden in production', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EnvDebugPage(
          env: _env,
          schema: EnvSchema.defaults,
          flavor: AppFlavor.production,
        ),
      ),
    );

    expect(find.text('Environment'), findsNothing);
  });
}
