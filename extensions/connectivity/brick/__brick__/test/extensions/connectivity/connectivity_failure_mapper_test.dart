import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/connectivity/connectivity_failure_mapper.dart';

void main() {
  test('wraps plugin errors as unavailable', () {
    final failure = mapConnectivityError(StateError('broken'));

    expect(failure.code, FailureCode.unavailable);
    expect(failure.kind, FailureKind.unavailable);
  });

  test('keeps an existing Failure', () {
    const original = Failure(
      code: FailureCode.networkOffline,
      message: 'offline',
      kind: FailureKind.network,
    );

    expect(mapConnectivityError(original), same(original));
  });
}
