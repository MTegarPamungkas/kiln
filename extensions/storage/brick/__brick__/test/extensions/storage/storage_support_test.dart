import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/storage/storage_support.dart';

import 'test_support.dart';

void main() {
  test('reports supported when keys can be read', () async {
    final support = StorageSupport(gateway: FakeStorageGateway());
    final info = await support.check();

    expect(info.isSupported, isTrue);
    expect(info.details['backend'], 'shared_preferences');
  });

  test('maps a missing plugin to unsupported platform', () async {
    final gateway = FakeStorageGateway()
      ..keysError = MissingPluginException('no preferences');
    final support = StorageSupport(gateway: gateway);

    expect((await support.check()).state, SupportState.unsupportedPlatform);
  });

  test('maps other errors to unavailable', () async {
    final gateway = FakeStorageGateway()..keysError = StateError('broken');
    final support = StorageSupport(gateway: gateway);

    final info = await support.check();

    expect(info.state, SupportState.unavailable);
    expect(info.toFailure().code, FailureCode.unavailable);
  });

  test('caches until cleared', () async {
    final gateway = FakeStorageGateway()..keysError = StateError('broken');
    final support = StorageSupport(gateway: gateway);

    await support.check();
    gateway.keysError = null;
    expect((await support.check()).isSupported, isFalse);
    support.clear();
    expect((await support.check()).isSupported, isTrue);
  });
}
