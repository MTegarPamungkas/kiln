import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/flavors/flavors_support.dart';

void main() {
  test('reports a missing flavor as not configured', () {
    const support = FlavorsSupport();

    final info = support.info;

    expect(info.state, SupportState.notConfigured);
    expect(info.toFailure().kind, FailureKind.configuration);
  });

  test('reports the active flavor and banner state', () {
    const development = FlavorsSupport(flavor: AppFlavor.development);
    const production = FlavorsSupport(flavor: AppFlavor.production);

    expect(development.info.details['flavor'], 'development');
    expect(development.info.details['banner'], isTrue);
    expect(production.info.details['flavor'], 'production');
    expect(production.info.details['banner'], isFalse);
  });
}
