import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:with_supabase/app/app.dart';
import 'package:with_supabase/core/l10n/app_strings.dart';

void main() {
  testWidgets('KilnApp renders the starter page', (tester) async {
    final registry = createTestRegistry();

    await tester.pumpWidget(KilnApp(registry: registry));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.readyTitle), findsOneWidget);
  });
}
