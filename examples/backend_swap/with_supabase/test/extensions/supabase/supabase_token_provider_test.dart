import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:with_supabase/extensions/supabase/supabase_token_provider.dart';

import 'test_support.dart';

void main() {
  late FakeSupabaseGateway gateway;
  late SupabaseTokenProvider tokens;

  setUp(() {
    gateway = FakeSupabaseGateway();
    tokens = SupabaseTokenProvider(gateway: gateway);
  });

  test('accessToken null saat belum ada sesi', () async {
    expect(await tokens.accessToken(), isNull);
  });

  test('accessToken diambil dari access token sesi aktif', () async {
    await gateway.signInWithPassword(
      email: 'user@kiln.dev',
      password: 'password123',
    );

    expect(await tokens.accessToken(), 'access-token');
    expect(gateway.forceRefreshRequested, isFalse);
  });

  test('forceRefresh meminta gateway memperbarui sesi lebih dulu', () async {
    await gateway.signInWithPassword(
      email: 'user@kiln.dev',
      password: 'password123',
    );
    gateway.forceRefreshRequested = false;

    expect(await tokens.accessToken(forceRefresh: true), 'access-token');
    expect(gateway.forceRefreshRequested, isTrue);
  });

  test('clear mengakhiri sesi sehingga token berikutnya null', () async {
    await gateway.signInWithPassword(
      email: 'user@kiln.dev',
      password: 'password123',
    );

    await tokens.clear();

    expect(gateway.signOutCalls, 1);
    expect(await tokens.accessToken(), isNull);
  });

  test('error gateway dipetakan menjadi Failure sesi', () async {
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
