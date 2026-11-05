import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/rest_auth/rest_auth.dart';
import 'package:{{app_name}}/extensions/rest_auth/rest_auth_config.dart';
import 'package:{{app_name}}/extensions/rest_auth/rest_token_store.dart';

const RestAuthConfig testConfig = RestAuthConfig(
  baseUrl: 'https://api.kiln.dev',
  forgotPasswordPath: '/auth/forgot-password',
  verifyEmailPath: '/auth/verify-email',
);

String makeJwt({String subject = 'user-1', DateTime? expiresAt}) {
  final header = base64Url
      .encode(utf8.encode('{"alg":"none"}'))
      .replaceAll('=', '');
  final expiry =
      (expiresAt ?? DateTime.now().toUtc().add(const Duration(hours: 1)))
          .millisecondsSinceEpoch ~/
      1000;
  final payload = base64Url
      .encode(utf8.encode('{"sub":"$subject","exp":$expiry}'))
      .replaceAll('=', '');
  return '$header.$payload.signature';
}

final class AuthHarness {
  AuthHarness({
    FakeHttpClient? client,
    InMemorySecureStorage? storage,
    RestAuthConfig config = testConfig,
    Clock clock = const SystemClock(),
  }) : client = client ?? FakeHttpClient(),
       storage = storage ?? InMemorySecureStorage() {
    this.client.onRequest ??= authServer;
    auth = RestAuth(
      client: this.client,
      store: RestTokenStore(storage: this.storage),
      config: config,
      clock: clock,
    );
  }

  final FakeHttpClient client;
  final InMemorySecureStorage storage;
  late final RestAuth auth;
}

Future<HttpResponse> authServer(HttpRequest request) async {
  final path = request.uri.path;
  final body = _body(request.body);
  if (path == '/auth/login') {
    if (body['password'] != 'password123') {
      return const HttpResponse(
        statusCode: 401,
        data: <String, Object?>{'message': 'Kredensial salah'},
      );
    }
    return HttpResponse(
      statusCode: 200,
      data: <String, Object?>{
        'access_token': makeJwt(),
        'refresh_token': 'refresh-token',
        'expires_in': 3600,
        'user': <String, Object?>{
          'id': 'user-1',
          'email': body['email'],
          'display_name': 'Tegar',
          'email_verified': true,
        },
      },
    );
  }
  if (path == '/auth/register') {
    return HttpResponse(
      statusCode: 201,
      data: <String, Object?>{
        'data': <String, Object?>{
          'tokens': <String, Object?>{
            'accessToken': makeJwt(subject: 'user-2'),
            'refreshToken': 'refresh-new',
          },
          'user': <String, Object?>{
            'id': 'user-2',
            'email': body['email'],
            'displayName': body['displayName'],
          },
        },
      },
    );
  }
  if (path == '/auth/refresh') {
    return HttpResponse(
      statusCode: 200,
      data: <String, Object?>{
        'accessToken': makeJwt(),
        'refreshToken': 'refresh-rotated',
      },
    );
  }
  if (path == '/auth/me') {
    return HttpResponse(
      statusCode: 200,
      data: <String, Object?>{
        'id': 'user-1',
        'email': 'user@kiln.dev',
        'displayName': 'Tegar P',
        'emailVerified': true,
      },
    );
  }
  if (path == '/auth/logout' ||
      path == '/auth/forgot-password' ||
      path == '/auth/verify-email') {
    return const HttpResponse(statusCode: 200);
  }
  return const HttpResponse(statusCode: 404);
}

Map<String, Object?> _body(Object? body) {
  if (body is String && body.isNotEmpty) {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      return <String, Object?>{
        for (final entry in decoded.entries) '${entry.key}': entry.value,
      };
    }
  }
  if (body is Map) {
    return <String, Object?>{
      for (final entry in body.entries) '${entry.key}': entry.value,
    };
  }
  return const <String, Object?>{};
}
