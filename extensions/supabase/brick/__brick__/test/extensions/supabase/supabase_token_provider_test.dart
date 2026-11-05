import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_token_provider.dart';

import 'test_support.dart';

void main() {
  late FakeSupabaseGateway gateway;
  late SupabaseTokenProvider tokens;

  setUp(() {
    gateway = FakeSupabaseGateway();
    tokens = SupabaseTokenProvider(gateway: gateway);
  });

  test('accessToken is null when there is no session', () async {
    expect(await tokens.accessToken(), isNull);
  });

  test('accessToken comes from the active session token', () async {
    await gateway.signInWithPassword(
      email: 'user@kiln.dev',
      password: 'password123',
    );

    expect(await tokens.accessToken(), 'access-token');
    expect(gateway.forceRefreshRequested, isFalse);
  });

  test('forceRefresh asks the gateway to refresh the session first', () async {
    await gateway.signInWithPassword(
      email: 'user@kiln.dev',
      password: 'password123',
    );
    gateway.forceRefreshRequested = false;

    expect(await tokens.accessToken(forceRefresh: true), 'access-token');
    expect(gateway.forceRefreshRequested, isTrue);
  });

  test('clear ends the session so the next token is null', () async {
    await gateway.signInWithPassword(
      email: 'user@kiln.dev',
      password: 'password123',
    );

    await tokens.clear();

    expect(gateway.signOutCalls, 1);
    expect(await tokens.accessToken(), isNull);
  });

  test('a gateway error maps to a session Failure', () async {
    final failing = _ThrowingGateway();

    await expectLater(
      SupabaseTokenProvider(gateway: failing).accessToken(),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.authSessionExpired,
        ),
      ),
    );
  });
}

final class _ThrowingGateway extends FakeSupabaseGateway {
  @override
  Future<String?> accessToken({bool forceRefresh = false}) async {
    throw const Failure(
      code: FailureCode.authSessionExpired,
      message: 'Sesi berakhir.',
      kind: FailureKind.session,
    );
  }
}
