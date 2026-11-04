import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

final class _Permissions implements Permissions {
  _Permissions(this.result);

  PermissionStatus result;
  Failure? failure;

  @override
  Future<PermissionStatus> status(PermissionKind kind) => _respond();

  @override
  Future<PermissionStatus> request(PermissionKind kind) => _respond();

  @override
  Future<PermissionStatus> ensure(
    PermissionKind kind, {
    bool requestIfDenied = true,
  }) => _respond();

  @override
  Future<bool> openSettings() async => true;

  Future<PermissionStatus> _respond() async {
    final programmedFailure = failure;
    if (programmedFailure != null) {
      throw programmedFailure;
    }
    return result;
  }
}

void main() {
  group('Gate', () {
    late GetItRegistry registry;
    late _Permissions permissions;

    setUp(() {
      registry = GetItRegistry();
      permissions = _Permissions(PermissionStatus.granted);
      registry.registerSingleton<Permissions>(permissions);
    });

    test('use reads a registered service and has probes registration', () {
      final gate = Gate(registry);

      expect(gate.has<Permissions>(), isTrue);
      expect(gate.use<Permissions>(), same(permissions));
      expect(gate.has<AuthRepository>(), isFalse);
    });

    test('typed getters return the registered contracts', () {
      final gate = Gate(registry);

      expect(gate.permissions, same(permissions));
    });

    test('call returns Ok with the produced value', () async {
      final gate = Gate(registry);

      final result = await gate.call(
        () => permissions.ensure(PermissionKind.camera),
      );

      expect(result, isA<Ok<PermissionStatus>>());
      expect(result.valueOrNull, PermissionStatus.granted);
    });

    test('call returns Err with the thrown Failure', () async {
      permissions.failure = const Failure(
        code: FailureCode.permissionDenied,
        message: 'Denied',
        kind: FailureKind.permission,
      );
      final gate = Gate(registry);

      final result = await gate.call(
        () => permissions.ensure(PermissionKind.camera),
      );

      expect(result, isA<Err<PermissionStatus>>());
      expect(result.failureOrNull?.code, FailureCode.permissionDenied);
    });

    test('call merges info into the failure details', () async {
      permissions.failure = const Failure(
        code: FailureCode.permissionDenied,
        message: 'Denied',
        kind: FailureKind.permission,
      );
      final gate = Gate(registry);

      final result = await gate.call(
        () => permissions.ensure(PermissionKind.camera),
        info: const {'operation': 'camera'},
      );

      expect(result.failureOrNull?.details['operation'], 'camera');
      expect(result.failureOrNull?.details['statusCode'], isNull);
    });

    test('call wraps an unexpected error into Err', () async {
      final gate = Gate(registry);

      final result = await gate.call(
        () async => throw StateError('boom'),
        code: FailureCode.unexpected,
      );

      expect(result, isA<Err<PermissionStatus>>());
      expect(result.failureOrNull?.code, FailureCode.unexpected);
    });

    test('requestPermission returns a Result in one call', () async {
      final gate = Gate(registry);

      final result = await gate.requestPermission(PermissionKind.camera);

      expect(result, isA<Ok<PermissionStatus>>());
      expect(result.valueOrNull, PermissionStatus.granted);
    });

    test('requestPermission surfaces failures as Err', () async {
      permissions.failure = const Failure(
        code: FailureCode.permissionPermanentlyDenied,
        message: 'Permanent',
      );
      final gate = Gate(registry);

      final result = await gate.requestPermission(PermissionKind.camera);

      expect(
        result.failureOrNull?.code,
        FailureCode.permissionPermanentlyDenied,
      );
    });
  });
}
