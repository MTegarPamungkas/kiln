import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/appwrite_push/appwrite_push_module.dart';

void main() {
  test('module declares its capability contract', () {
    final module = AppwritePushModule();

    expect(module.id, 'appwrite_push');
    expect(module.provides, <String>{'push_transport'});
    expect(module.requires, <String>{'push_targets'});
    expect(module.optionalRequires, <String>{'notifications'});
  });

  test('autoRegister can be disabled for explicit opt-in apps', () {
    final module = AppwritePushModule(autoRegister: false);

    expect(module.autoRegister, isFalse);
  });
}
