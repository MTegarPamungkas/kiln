import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:with_appwrite/core/l10n/core_copy.dart';

import 'support/app_fixture.dart';
import 'support/test_core_copy.dart';

void main() {
  testWidgets('KilnApp renders the application root', (tester) async {
    final registry = createTestRegistry();
    registry.registerSingleton<CoreCopy>(const TestCoreCopy());

    await tester.pumpWidget(buildTestApp(registry));
    await tester.pumpAndSettle();

    expect(find.text('Test App'), findsOneWidget);
  });
}
