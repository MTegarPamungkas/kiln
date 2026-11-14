import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/appwrite_push_native/appwrite_push_native_module.dart';

void main() {
  test('module declares its capability contract', () {
    final module = AppwritePushNativeModule();

    expect(module.id, 'appwrite_push_native');
    expect(module.provides, <String>{'push_transport'});
    expect(module.requires, <String>{'auth'});
    expect(module.platforms, <String>{'android', 'ios'});
  });

  test('autoSubscribe can be disabled for explicit opt-in apps', () {
    final module = AppwritePushNativeModule(autoSubscribe: false);

    expect(module.autoSubscribe, isFalse);
  });
}
