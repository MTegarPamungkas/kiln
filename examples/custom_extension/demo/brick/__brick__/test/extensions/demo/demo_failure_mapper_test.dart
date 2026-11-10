import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';

import '../../../lib/extensions/demo/demo_failure_mapper.dart';

void main() {
  test('maps unexpected errors to Failure', () {
    final failure = mapDemoError(StateError('broken'));

    expect(failure.code, FailureCode.unexpected);
    expect(failure.cause, isA<StateError>());
  });
}
