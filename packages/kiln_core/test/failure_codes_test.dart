import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

void main() {
  group('FailureCode', () {
    test('known codes are unique and non-empty', () {
      final values = FailureCode.known.map((code) => code.value).toList();

      expect(values, isNotEmpty);
      expect(values.toSet().length, values.length);
      expect(values.every((value) => value.isNotEmpty), isTrue);
    });

    test('shipped values are stable', () {
      expect(FailureCode.networkTimeout.value, 'network.timeout');
      expect(
        FailureCode.authInvalidCredentials.value,
        'auth.invalid_credentials',
      );
      expect(FailureCode.permissionDenied.value, 'permission.denied');
      expect(FailureCode.storageReadFailed.value, 'storage.read_failed');
      expect(FailureCode.cancelled.value, 'cancelled');
    });

    test('codes compare by value', () {
      expect(
        const FailureCode('custom.code'),
        const FailureCode('custom.code'),
      );
      expect(
        const FailureCode('custom.code'),
        isNot(const FailureCode('other')),
      );
      expect(
        const FailureCode('custom.code').hashCode,
        const FailureCode('custom.code').hashCode,
      );
    });

    test('toString returns the stable value', () {
      expect(FailureCode.networkOffline.toString(), 'network.offline');
    });
  });
}
