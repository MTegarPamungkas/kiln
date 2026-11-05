import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/rest_auth/jwt_expiry.dart';

import 'test_support.dart';

void main() {
  test('reads exp and subject without verifying the signature', () {
    final expiry = DateTime.utc(2026, 11, 2, 9);
    final token = makeJwt(subject: 'user-7', expiresAt: expiry);

    expect(JwtExpiry.expiryOf(token), expiry);
    expect(JwtExpiry.subjectOf(token), 'user-7');
  });

  test('treats a token inside the leeway as expired', () {
    final clock = FixedClock(DateTime.utc(2026, 11, 2, 9));
    final token = makeJwt(expiresAt: DateTime.utc(2026, 11, 2, 9, 0, 10));

    expect(JwtExpiry.isExpired(token, clock), isTrue);
    expect(
      JwtExpiry.isExpired(
        makeJwt(expiresAt: DateTime.utc(2026, 11, 2, 9, 5)),
        clock,
      ),
      isFalse,
    );
  });

  test('returns null for opaque tokens', () {
    expect(JwtExpiry.expiryOf('opaque-token'), isNull);
    expect(JwtExpiry.subjectOf('opaque-token'), isNull);
    expect(
      JwtExpiry.isExpired('opaque-token', FixedClock(DateTime.utc(2026))),
      isFalse,
    );
  });
}
