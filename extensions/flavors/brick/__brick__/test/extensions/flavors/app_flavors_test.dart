import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/flavors/app_flavors.dart';

void main() {
  test('defines the standard flavors', () {
    expect(AppFlavors.development, isNot(AppFlavors.production));
    expect(AppFlavors.staging.isProduction, isFalse);
    expect(AppFlavors.production.isProduction, isTrue);
    expect(
      AppFlavors.values.map((flavor) => flavor.name),
      ['development', 'staging', 'production'],
    );
  });
}
