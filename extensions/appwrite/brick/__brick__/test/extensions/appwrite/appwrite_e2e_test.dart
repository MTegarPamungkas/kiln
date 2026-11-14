import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// kiln_core also exports an `HttpClient` contract; the live overrides below
// need dart:io's.
import 'package:kiln_core/kiln_core.dart' hide HttpClient;
import 'package:kiln_testing/kiln_testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:{{app_name}}/extensions/appwrite/appwrite_account.dart';
import 'package:{{app_name}}/extensions/appwrite/appwrite_config.dart';
import 'package:{{app_name}}/extensions/appwrite/appwrite_module.dart';

/// Live end-to-end suite against a real Appwrite server.
///
/// Skipped unless the environment opts in, so generated apps and CI run the
/// offline suites only:
///
/// ```
/// KILN_APPWRITE_E2E=1
/// KILN_APPWRITE_ENDPOINT=https://appwrite.example.com/v1
/// KILN_APPWRITE_PROJECT=<project id>
/// KILN_APPWRITE_TEST_EMAIL=<existing user email>
/// KILN_APPWRITE_TEST_PASSWORD=<that user's password>
/// ```
///
/// `database_id` and `bucket_id` follow the extension defaults unless
/// `KILN_APPWRITE_DATABASE` / `KILN_APPWRITE_BUCKET` override them. The server
/// needs the database, tables, bucket, and the test user to exist; the
/// provisioning tool prepares them (see the extension's e2e-testing doc).
void main() {
  final environment = Platform.environment;
  // Nullable values stay absent until the environment opts in: the contract
  // calls below are evaluated eagerly even when the group is skipped, so they
  // must not unwrap anything here.
  final endpoint = environment['KILN_APPWRITE_ENDPOINT'] ?? '';
  final projectId = environment['KILN_APPWRITE_PROJECT'] ?? '';
  final databaseId = environment['KILN_APPWRITE_DATABASE'] ?? 'kiln';
  final bucketId = environment['KILN_APPWRITE_BUCKET'] ?? 'kiln_files';
  final validEmail = environment['KILN_APPWRITE_TEST_EMAIL'] ?? '';
  final validPassword = environment['KILN_APPWRITE_TEST_PASSWORD'] ?? '';

  final enabled =
      environment['KILN_APPWRITE_E2E'] == '1' &&
      endpoint.isNotEmpty &&
      projectId.isNotEmpty &&
      validEmail.isNotEmpty &&
      validPassword.isNotEmpty;
  final skipReason = enabled
      ? null
      : 'Set KILN_APPWRITE_E2E=1 and the KILN_APPWRITE_ENDPOINT, '
            'KILN_APPWRITE_PROJECT, KILN_APPWRITE_TEST_EMAIL, and '
            'KILN_APPWRITE_TEST_PASSWORD variables to run against a live '
            'Appwrite server.';

  // A unique address per run, because Appwrite rejects duplicate emails and
  // the signUp contract does not clean up after itself.
  final signUpEmail =
      environment['KILN_APPWRITE_SIGNUP_EMAIL'] ??
      'e2e-signup-${DateTime.now().microsecondsSinceEpoch}@kiln.test';
  // The live functions test only runs when a deployed function id is given;
  // deployments are backend-specific and not part of provisioning.
  final functionId = environment['KILN_APPWRITE_FUNCTION_ID'];

  final pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  final createdModules = <AppwriteModule>[];

  /// Cookie captured from the suite's first real sign-in. Appwrite rate-limits
  /// login attempts per user, so later registries restore this session instead
  /// of posting another login.
  String? cachedSessionCookie;

  /// Only set once [buildRegistry] initialized the test binding, so a skipped
  /// suite does not touch the binding in [tearDownAll].
  var bindingInitialized = false;

  Future<GetItRegistry> buildRegistry({bool signIn = false}) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    bindingInitialized = true;
    // flutter_test installs overrides that answer every HttpClient with an
    // empty 400 to keep tests offline; the live suite needs real sockets.
    HttpOverrides.global = _LiveHttpOverrides();
    final reuseSession = signIn && cachedSessionCookie != null;
    SharedPreferences.setMockInitialValues(<String, Object>{
      if (reuseSession)
        SdkAppwriteAccount.sessionCookieKey: cachedSessionCookie!,
    });
    final supportDirectory = await Directory.systemTemp.createTemp(
      'kiln_appwrite_e2e_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (call) async {
          return supportDirectory.path;
        });

    final config = AppwriteConfig(
      endpoint: endpoint,
      projectId: projectId,
      databaseId: databaseId,
      bucketId: bucketId,
    );
    final registry = GetItRegistry();
    final module = AppwriteModule(
      config: config,
      flavor: AppFlavor.development,
    );
    module.register(registry);
    await module.ready(registry);
    // Database and storage servers grant row and file CRUD to the signed-in
    // `users` role; the auth suite manages its own sessions instead.
    if (signIn) {
      if (cachedSessionCookie == null) {
        await registry
            .read<AuthRepository>()
            .signIn(email: validEmail, password: validPassword);
        cachedSessionCookie =
            (await SharedPreferences.getInstance())
                .getString(SdkAppwriteAccount.sessionCookieKey);
      } else {
        expect(
          registry.read<AuthRepository>().currentSession,
          isNotNull,
          reason: 'the reused session cookie should restore sign-in state',
        );
      }
    }
    createdModules.add(module);
    return registry;
  }

  tearDownAll(() async {
    if (bindingInitialized) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProvider, null);
    }
    for (final module in createdModules) {
      await module.dispose();
    }
    createdModules.clear();
  });

  group('Appwrite live e2e', skip: skipReason, () {
    authRepositoryContract(
      description: 'AppwriteAuth against a live server',
      validEmail: validEmail,
      validPassword: validPassword,
      signUpEmail: signUpEmail,
      create: () async => (await buildRegistry()).read<AuthRepository>(),
    );

    remoteDatabaseContract(
      description: 'AppwriteRemoteDatabase against a live server',
      timeout: const Duration(seconds: 10),
      create: () async =>
          (await buildRegistry(signIn: true)).read<RemoteDatabase>(),
    );

    fileStorageContract(
      description: 'AppwriteFileStorage against a live server',
      create: () async =>
          (await buildRegistry(signIn: true)).read<FileStorage>(),
    );

    test('token provider mints a short-lived JWT for the session', () async {
      // Reuses the cached session: no extra login POST, which keeps the suite
      // under Appwrite's login rate limit.
      final registry = await buildRegistry(signIn: true);
      final tokens = registry.read<TokenProvider>();

      final token = await tokens.accessToken();
      expect(token, isNotNull);
      expect(token, isNotEmpty);
      expect(
        await tokens.accessToken(forceRefresh: true),
        isNotEmpty,
      );

      await tokens.clear();
      expect(await tokens.accessToken(), isNotNull);
    });

    test('invoke runs a deployed cloud function', () async {
      final liveFunctionId = functionId;
      if (liveFunctionId == null || liveFunctionId.isEmpty) {
        return;
      }
      final registry = await buildRegistry(signIn: true);
      final functions = registry.read<CloudFunctions>();

      final execution = await functions.invoke(
        liveFunctionId,
        body: <String, Object?>{'name': 'Kiln e2e'},
      );

      expect(execution.status, 'completed');
      expect(execution.body, isNotEmpty);
    });

    test('watch emits null after the row is deleted', () async {
      final registry = await buildRegistry(signIn: true);
      final database = registry.read<RemoteDatabase>();

      final created = await database.create('users', <String, Object?>{
        'name': 'Ephemeral',
      });
      final id = '${created['id']}';

      // Wait for the current document on the same subscription before
      // deleting, so the delete cannot race the realtime handshake.
      final seen = Completer<Map<String, Object?>?>();
      final deleted = Completer<void>();
      final subscription = database.watch('users', id).listen((document) {
        if (document == null) {
          if (!deleted.isCompleted) {
            deleted.complete();
          }
        } else if (!seen.isCompleted) {
          seen.complete(document);
        }
      });
      expect(
        (await seen.future.timeout(const Duration(seconds: 10)))?['name'],
        'Ephemeral',
      );

      await database.delete('users', id);
      await deleted.future.timeout(const Duration(seconds: 10));
      await subscription.cancel();
    });
  });
}

/// Restores real sockets inside the test binding. The development flavor
/// accepts self-signed certificates, matching self-hosted setups.
final class _LiveHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (certificate, host, port) => true;
  }
}
