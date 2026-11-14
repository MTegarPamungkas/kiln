import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart' hide HttpClient;
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/appwrite_push_native/appwrite_push_native_transport.dart';

/// Live end-to-end suite for Appwrite Push.
///
/// Skipped unless the environment opts in. Sending the push needs a server API
/// key with the messaging scope, so this suite is for the repository's e2e
/// runs, not generated apps:
///
/// ```
/// KILN_APPWRITE_PUSH_E2E=1
/// KILN_APPWRITE_ENDPOINT=https://appwrite.example.com/v1
/// KILN_APPWRITE_PROJECT=<project id>
/// KILN_APPWRITE_API_KEY=<server key>
/// KILN_APPWRITE_TEST_EMAIL=<existing user email>
/// KILN_APPWRITE_TEST_PASSWORD=<that user's password>
/// ```
void main() {
  final environment = Platform.environment;
  final endpoint = environment['KILN_APPWRITE_ENDPOINT'] ?? '';
  final projectId = environment['KILN_APPWRITE_PROJECT'] ?? '';
  final apiKey = environment['KILN_APPWRITE_API_KEY'] ?? '';
  final validEmail = environment['KILN_APPWRITE_TEST_EMAIL'] ?? '';
  final validPassword = environment['KILN_APPWRITE_TEST_PASSWORD'] ?? '';
  final pushEndpoint = environment['KILN_APPWRITE_PUSH_ENDPOINT'] ?? '';
  final selfSigned = environment['KILN_APPWRITE_PUSH_SELF_SIGNED'] == '1';

  final enabled =
      environment['KILN_APPWRITE_PUSH_E2E'] == '1' &&
      endpoint.isNotEmpty &&
      projectId.isNotEmpty &&
      apiKey.isNotEmpty &&
      validEmail.isNotEmpty &&
      validPassword.isNotEmpty;
  final skipReason = enabled
      ? null
      : 'Set KILN_APPWRITE_PUSH_E2E=1 and the KILN_APPWRITE_ENDPOINT, '
            'KILN_APPWRITE_PROJECT, KILN_APPWRITE_API_KEY, '
            'KILN_APPWRITE_TEST_EMAIL, and KILN_APPWRITE_TEST_PASSWORD '
            'variables to run against a live server.';

  group('Appwrite Push live e2e', skip: skipReason, () {
    test('receives a push sent to the signed-in user', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      HttpOverrides.global = _LiveHttpOverrides();
      final supportDirectory = await Directory.systemTemp.createTemp(
        'kiln_push_e2e_',
      );
      const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProvider, (call) async {
            return supportDirectory.path;
          });
      addTearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathProvider, null);
        await supportDirectory.delete(recursive: true);
      });

      final session = await _signIn(
        endpoint: endpoint,
        projectId: projectId,
        email: validEmail,
        password: validPassword,
      );
      final client = appwrite.Client(selfSigned: selfSigned)
        ..setEndpoint(endpoint)
        ..setProject(projectId)
        ..setSession(session.cookie);
      final auth = FakeAuthRepository(
        validEmail: validEmail,
        validPassword: validPassword,
      );
      await auth.signIn(email: validEmail, password: validPassword);

      final transport = AppwritePushNativeTransport(
        client: client,
        auth: auth,
        pushEndpoint: pushEndpoint,
        notificationTitle: 'Kiln E2E',
        background: false,
      );
      addTearDown(transport.dispose);

      expect(await transport.token(), isNull);

      final received = Completer<PushEnvelope>();
      final subscription = transport.foreground.listen((envelope) {
        if (!received.isCompleted) {
          received.complete(envelope);
        }
      });
      addTearDown(subscription.cancel);

      await transport.start();
      expect(
        transport.isSubscribed,
        isTrue,
        reason: '${transport.lastError}',
      );

      final response = await _send(
        method: 'POST',
        url: '$endpoint/messaging/messages/push',
        headers: <String, String>{
          'X-Appwrite-Project': projectId,
          'X-Appwrite-Key': apiKey,
        },
        body: <String, Object?>{
          'messageId': 'e2e-push-${DateTime.now().microsecondsSinceEpoch}',
          'title': 'Kiln E2E',
          'body': 'Push body',
          'users': <String>[session.userId],
          'data': <String, Object?>{'route': '/e2e'},
          'draft': false,
        },
      );
      expect(response.status, inInclusiveRange(200, 299), reason: response.body);

      final envelope = await received.future.timeout(
        const Duration(seconds: 45),
      );
      expect(envelope.title, 'Kiln E2E');
      expect(envelope.body, 'Push body');
      expect(envelope.data['route'], '/e2e');
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}

final class _Session {
  const _Session({required this.cookie, required this.userId});

  final String cookie;
  final String userId;
}

Future<_Session> _signIn({
  required String endpoint,
  required String projectId,
  required String email,
  required String password,
}) async {
  final response = await _send(
    method: 'POST',
    url: '$endpoint/account/sessions/email',
    headers: <String, String>{'X-Appwrite-Project': projectId},
    body: <String, Object?>{'email': email, 'password': password},
  );
  if (response.status != 201) {
    throw StateError('Sign-in failed (${response.status}): ${response.body}');
  }
  final cookie = response.cookies
      .map((value) => value.trim())
      .where((value) => value.startsWith('a_session_$projectId='))
      .map((value) => value.substring('a_session_$projectId='.length))
      .map((value) => value.split(';').first)
      .firstWhere((value) => value.isNotEmpty, orElse: () => '');
  if (cookie.isEmpty) {
    throw StateError('Sign-in response did not set a session cookie.');
  }
  final json = jsonDecode(response.body) as Map<String, Object?>;
  return _Session(
    cookie: Uri.decodeComponent(cookie),
    userId: json['userId'] as String? ?? '',
  );
}

final class _Response {
  const _Response({
    required this.status,
    required this.body,
    this.cookies = const <String>[],
  });

  final int status;
  final String body;
  final List<String> cookies;
}

Future<_Response> _send({
  required String method,
  required String url,
  Map<String, String> headers = const <String, String>{},
  Object? body,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, Uri.parse(url));
    request.headers.contentType = ContentType.json;
    for (final entry in headers.entries) {
      request.headers.set(entry.key, entry.value);
    }
    if (body != null) {
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    return _Response(
      status: response.statusCode,
      body: await response.transform(utf8.decoder).join(),
      cookies: response.headers[HttpHeaders.setCookieHeader] ?? const <String>[],
    );
  } finally {
    client.close(force: true);
  }
}

/// Restores real sockets inside the test binding; the development flavor
/// accepts self-signed certificates, matching self-hosted setups.
final class _LiveHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (certificate, host, port) => true;
  }
}
