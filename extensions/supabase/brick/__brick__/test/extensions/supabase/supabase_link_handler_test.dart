import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_gateway.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_link_handler.dart';

import 'test_support.dart';

void main() {
  late FakeSupabaseGateway gateway;
  late FakeDeepLinks deepLinks;
  late SupabaseLinkHandler handler;
  late List<SupabaseSession> sessions;

  setUp(() {
    gateway = FakeSupabaseGateway();
    deepLinks = FakeDeepLinks();
    sessions = <SupabaseSession>[];
    handler = SupabaseLinkHandler(
      gateway: gateway,
      deepLinks: deepLinks,
      onSession: sessions.add,
    );
  });

  tearDown(() async {
    await handler.dispose();
    await deepLinks.dispose();
  });

  test('start memproses tautan awal dengan kode PKCE', () async {
    deepLinks.initialLink = Uri.parse('kiln-auth://auth-callback?code=abc123');

    await handler.start();

    expect(gateway.exchangedCodes, ['abc123']);
    expect(sessions, hasLength(1));
    expect(handler.lastSession?.userId, 'user-1');
    expect(handler.isAttached, isTrue);
  });

  test('tautan masuk dengan token_hash diverifikasi lewat OTP', () async {
    await handler.start();

    deepLinks.emit(
      Uri.parse('kiln-auth://auth-callback?token_hash=hash-1&type=signup'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(gateway.verifiedTokenHashes, ['hash-1']);
    expect(gateway.verifiedTypes, ['signup']);
    expect(sessions, hasLength(1));
  });

  test('parameter di fragment juga dibaca', () async {
    await handler.start();

    deepLinks.emit(Uri.parse('kiln-auth://auth-callback#code=fragment-code'));
    await Future<void>.delayed(Duration.zero);

    expect(gateway.exchangedCodes, ['fragment-code']);
  });

  test('tautan tanpa parameter auth diabaikan', () async {
    await handler.start();

    deepLinks.emit(Uri.parse('kiln-auth://auth-callback?foo=bar'));
    await Future<void>.delayed(Duration.zero);

    expect(gateway.exchangedCodes, isEmpty);
    expect(gateway.verifiedTokenHashes, isEmpty);
    expect(sessions, isEmpty);
  });

  test('error dari Supabase dilaporkan lewat stream failures', () async {
    await handler.start();
    final failures = <Failure>[];
    final subscription = handler.failures.listen(failures.add);

    deepLinks.emit(
      Uri.parse(
        'kiln-auth://auth-callback?error=access_denied'
        '&error_description=User+denied+the+request',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(failures, hasLength(1));
    expect(failures.single.kind, FailureKind.authentication);
    expect(failures.single.message, contains('User denied the request'));

    await subscription.cancel();
  });

  test('dispose berhenti mendengarkan tautan baru', () async {
    await handler.start();
    await handler.dispose();

    deepLinks.emit(Uri.parse('kiln-auth://auth-callback?code=late'));
    await Future<void>.delayed(Duration.zero);

    expect(handler.isAttached, isFalse);
    expect(gateway.exchangedCodes, isEmpty);
  });

  test('tanpa DeepLinks handler tidak memasang langganan', () async {
    final detached = SupabaseLinkHandler(gateway: gateway);

    await detached.start();

    expect(detached.isAttached, isFalse);
    await detached.dispose();
  });
}
