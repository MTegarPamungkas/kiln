import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/app/app.dart';
import 'package:full_stack/core/l10n/app_strings.dart';
import 'package:full_stack/extensions/bloc/bloc_module.dart';

void main() {
  testWidgets('application bootstraps with the bloc wrapper', (tester) async {
    final registry = await KilnBootstrap.run(
      modules: const <KilnModule>[BlocModule()],
    );

    await tester.pumpWidget(KilnApp(registry: registry));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.readyTitle), findsOneWidget);
  });
}
