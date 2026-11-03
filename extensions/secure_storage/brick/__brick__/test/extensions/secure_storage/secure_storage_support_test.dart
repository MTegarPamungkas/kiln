import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/secure_storage/secure_storage_support.dart';

import 'test_support.dart';

void main() {
  test('reports supported when the secure store answers', () async {
    final support = SecureStorageSupport(
      gateway: FakeSecureStorageGateway(values: <String, String>{'k': 'v'}),
    );

    final info = await support.check();

    expect(info.isSupported, isTrue);
  });

  test('caches the probe until cleared', () async {
    final gateway = FakeSecureStorageGateway();
    final support = SecureStorageSupport(gateway: gateway);

    await support.check();
    gateway.readAllError = StateError('now broken');
    expect((await support.check()).isSupported, isTrue);

    support.clear();
    expect((await support.check()).isSupported, isFalse);
  });

  test('maps a missing plugin to unsupported platform', () async {
    final gateway = FakeSecureStorageGateway()
      ..readAllError = MissingPluginException('no keystore');
    final support = SecureStorageSupport(gateway: gateway);

    final info = await support.check();

    expect(info.state, SupportState.unsupportedPlatform);
    expect(info.toFailure().code, FailureCode.unsupportedPlatform);
  });

  test('maps a failed desktop service to unavailable', () async {
    final gateway = FakeSecureStorageGateway()
      ..readAllError = PlatformException(code: 'unavailable');
    final support = SecureStorageSupport(gateway: gateway);

    final info = await support.check();

    expect(info.state, SupportState.unavailable);
    expect(info.toFailure().code, FailureCode.unavailable);
  });
}
