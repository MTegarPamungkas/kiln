import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/flavors/flavor_x.dart';

void main() {
  test('selects a value per flavor', () {
    String label(AppFlavor flavor) => flavor.valueFor<String>(
      development: 'DEV',
      staging: 'STG',
      production: 'PROD',
      orElse: 'OTHER',
    );

    expect(label(AppFlavor.development), 'DEV');
    expect(label(AppFlavor.staging), 'STG');
    expect(label(AppFlavor.production), 'PROD');
    expect(label(const AppFlavor('qa')), 'OTHER');
  });
}
