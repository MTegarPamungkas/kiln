import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/rest_auth/auth_response_parser.dart';
import 'package:full_stack/extensions/rest_auth/jwt_expiry.dart';

void main() {
  test('parses snake case tokens and top-level user', () {
    const parser = AuthResponseParser();
    final parsed = parser.parse(<String, Object?>{
      'access_token': 'access',
      'refresh_token': 'refresh',
      'user': <String, Object?>{'id': 'u1'},
    });

    expect(parsed.tokens.accessToken, 'access');
    expect(parsed.tokens.refreshToken, 'refresh');
    expect(parsed.user['id'], 'u1');
  });

  test('parses nested camelCase tokens and expiry', () {
    const parser = AuthResponseParser();
    final parsed = parser.parse(<String, Object?>{
      'data': <String, Object?>{
        'tokens': <String, Object?>{
          'accessToken': 'access',
          'refreshToken': 'refresh',
          'expiresIn': 120,
        },
        'user': <String, Object?>{'id': 'u2'},
      },
    });

    expect(parsed.tokens.accessToken, 'access');
    expect(parsed.tokens.expiresAt, isNotNull);
    expect(parsed.user['id'], 'u2');
  });

  test('falls back to the JWT subject', () {
    final token = _jwt('subject-1');
    const parser = AuthResponseParser();
    final parsed = parser.parse(<String, Object?>{'token': token});

    expect(JwtExpiry.subjectOf(parsed.tokens.accessToken), 'subject-1');
  });

  test('rejects a response without a token', () {
    const parser = AuthResponseParser();

    expect(
      () => parser.parse(const <String, Object?>{'user': <String, Object?>{}}),
      throwsA(isA<Failure>()),
    );
  });
}

String _jwt(String subject) {
  const header = 'eyJhbGciOiJub25lIn0';
  final payload = base64Url
      .encode('{"sub":"$subject"}'.codeUnits)
      .replaceAll('=', '');
  return '$header.$payload.';
}
