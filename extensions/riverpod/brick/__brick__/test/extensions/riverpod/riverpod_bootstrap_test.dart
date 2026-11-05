import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/app/app.dart';
import 'package:{{app_name}}/core/l10n/core_copy.dart';
import 'package:{{app_name}}/extensions/riverpod/riverpod_module.dart';

void main() {
  testWidgets('application bootstraps with the riverpod wrapper', (
    tester,
  ) async {
    final registry = await KilnBootstrap.run(
      modules: const <KilnModule>[RiverpodModule()],
    );
    registry.registerSingleton<CoreCopy>(const _TestCopy());

    await tester.pumpWidget(
      KilnApp(registry: registry, home: const SizedBox.shrink()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(KilnApp), findsOneWidget);
  });
}

final class _TestCopy implements CoreCopy {
  const _TestCopy();

  @override
  String appTitle(BuildContext context) => 'Test App';

  @override
  String readyTitle(BuildContext context) => 'Ready';

  @override
  String readyBody(BuildContext context) => 'The app is ready.';

  @override
  String starterHint(BuildContext context) => 'Install an extension.';

  @override
  String errorTitle(BuildContext context) => 'Startup failed';

  @override
  String errorBody(BuildContext context) => 'Check the configuration.';

  @override
  String retry(BuildContext context) => 'Retry';
}
