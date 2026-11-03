import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{name}}/app/app.dart';
import 'package:{{name}}/core/l10n/core_copy.dart';

import 'support/test_core_copy.dart';

void main() {
  testWidgets('KilnApp renders the starter page', (tester) async {
    final registry = createTestRegistry();
    registry.registerSingleton<CoreCopy>(const TestCoreCopy());

    await tester.pumpWidget(KilnApp(registry: registry));
    await tester.pumpAndSettle();

    expect(find.text('Ready'), findsOneWidget);
  });
}
