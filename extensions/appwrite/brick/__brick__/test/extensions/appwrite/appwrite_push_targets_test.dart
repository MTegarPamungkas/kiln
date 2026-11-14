import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// kiln_core also exports an `HttpClient` contract; the overrides below need
// dart:io's.
import 'package:kiln_core/kiln_core.dart' hide HttpClient;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:{{app_name}}/extensions/appwrite/appwrite_push_targets.dart';

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
      'kiln_appwrite_push_targets_',
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

  test('an empty token is rejected before any network call', () async {
    final targets = _offlineTargets();

    await expectLater(
      targets.register(token: '  '),
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

  test('an empty target id is rejected before any network call', () async {
    final targets = _offlineTargets();

    await expectLater(
      targets.unregister(targetId: ' '),
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
    final targets = _offlineTargets();

    await expectLater(
      targets.register(token: 'fcm-token'),
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

AppwritePushTargets _offlineTargets() {
  // The real SDK service over an endpoint that cannot connect: every call
  // fails with a transport error without touching a real backend.
  return AppwritePushTargets(
    account: Account(
      Client(endPoint: 'http://127.0.0.1:1/v1')..setProject('offline-test'),
    ),
  );
}

final class _RealHttpOverrides extends HttpOverrides {}
