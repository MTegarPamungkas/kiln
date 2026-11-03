import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/appwrite/appwrite_account_management.dart';
import 'package:{{app_name}}/extensions/appwrite/appwrite_auth.dart';
import 'package:{{app_name}}/extensions/appwrite/appwrite_config.dart';
import 'package:{{app_name}}/extensions/appwrite/appwrite_file_storage.dart';
import 'package:{{app_name}}/extensions/appwrite/appwrite_module.dart';
import 'package:{{app_name}}/extensions/appwrite/appwrite_remote_database.dart';
import 'package:{{app_name}}/extensions/appwrite/appwrite_session_bridge.dart';
import 'package:{{app_name}}/extensions/appwrite/appwrite_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  late Directory supportDirectory;

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'kiln_appwrite_module_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProvider,
          (call) async => supportDirectory.path,
        );
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

  test('module registers every Appwrite contract', () async {
    const config = AppwriteConfig(
      endpoint: 'https://appwrite.test/v1',
      projectId: 'project',
      databaseId: 'database',
      bucketId: 'bucket',
    );
    final registry = GetItRegistry();
    final module = AppwriteModule(config: config);

    module.register(registry);

    expect(registry.read<AppwriteConfig>(), same(config));
    expect(registry.read<AppwriteSupport>(), isA<AppwriteSupport>());
    expect(registry.read<AuthRepository>(), isA<AppwriteAuth>());
    expect(
      registry.read<AccountManagement>(),
      isA<AppwriteAccountManagement>(),
    );
    expect(registry.read<RemoteDatabase>(), isA<AppwriteRemoteDatabase>());
    expect(registry.read<FileStorage>(), isA<AppwriteFileStorage>());
    expect(registry.read<TokenProvider>(), isA<AppwriteTokenProvider>());

    await module.dispose();
  });

  test('module exposes the capabilities the manifest promises', () {
    final module = AppwriteModule();

    expect(module.id, 'appwrite');
    expect(module.provides, <String>{
      'auth',
      'remote_database',
      'file_storage',
    });
    expect(module.optionalRequires, isEmpty);
  });
}
