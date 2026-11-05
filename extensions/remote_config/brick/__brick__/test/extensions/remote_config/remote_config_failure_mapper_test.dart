import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_failure_mapper.dart';

void main() {
  group('RemoteConfigFailureMapper', () {
    test('passes an existing Failure through', () {
      const failure = Failure(
        code: FailureCode.networkTimeout,
        message: 'timeout',
        kind: FailureKind.network,
      );

      expect(const RemoteConfigFailureMapper().map(failure), same(failure));
    });

    test('wraps other errors as unavailable', () {
      final failure = const RemoteConfigFailureMapper().map(
        StateError('down'),
      );

      expect(failure.kind, FailureKind.unavailable);
      expect(failure.code, FailureCode.unavailable);
    });
  });
}
