import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
// kiln_core also exports an `HttpClient` contract; the overrides below need
// dart:io's.
import 'package:kiln_core/kiln_core.dart' hide HttpClient;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:{{app_name}}/extensions/appwrite/appwrite_functions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  late Directory supportDirectory;

  setUp(() async {
    // flutter_test answers every HttpClient with an empty 400; transport-error
    // mapping needs real sockets against an unreachable local port.
    HttpOverrides.global = _RealHttpOverrides();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    supportDirectory = await Directory.systemTemp.createTemp(
      'kiln_appwrite_functions_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (call) async {
          return supportDirectory.path;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, null);
    try {
      await supportDirectory.delete(recursive: true);
    } on FileSystemException {
      // The client can hold the cookie handle briefly on Windows.
    }
  });

  test('an empty function id is rejected before any network call', () async {
    final functions = AppwriteFunctions(functions: _offlineFunctions());

    await expectLater(
      functions.invoke('  '),
      throwsA(
        isA<Failure>()
            .having(
              (value) => value.code,
              'code',
              FailureCode.validationInvalidInput,
            )
            .having(
              (value) => value.kind,
              'kind',
              FailureKind.validation,
            ),
      ),
    );
  });

  test('an unsupported HTTP method is rejected before any network call', () {
    final functions = AppwriteFunctions(functions: _offlineFunctions());

    expect(
      () => functions.invoke('hello-kiln', method: 'BREW'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.validationInvalidInput,
        ),
      ),
    );
  });

  test('a transport error maps to a retryable network failure', () async {
    final functions = AppwriteFunctions(functions: _offlineFunctions());

    await expectLater(
      functions.invoke('hello-kiln'),
      throwsA(
        isA<Failure>()
            .having(
              (value) => value.kind,
              'kind',
              FailureKind.network,
            )
            .having(
              (value) => value.isRetryable,
              'isRetryable',
              isTrue,
            ),
      ),
    );
  });
}

Functions _offlineFunctions() {
  // The real SDK service over an endpoint that cannot connect: every call
  // fails with a transport error without touching a real backend.
  return Functions(
    Client(endPoint: 'http://127.0.0.1:1/v1')..setProject('offline-test'),
  );
}

/// Replaces flutter_test's empty-400 mock overrides with plain ones, so
/// transport-error mapping can reach real sockets.
final class _RealHttpOverrides extends HttpOverrides {}
