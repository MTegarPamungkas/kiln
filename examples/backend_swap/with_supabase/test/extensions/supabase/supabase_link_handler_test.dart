import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:with_supabase/extensions/supabase/supabase_gateway.dart';
import 'package:with_supabase/extensions/supabase/supabase_link_handler.dart';

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

  test('start processes the initial link with a PKCE code', () async {
    deepLinks.initialLink = Uri.parse('kiln-auth://auth-callback?code=abc123');

    await handler.start();

    expect(gateway.exchangedCodes, ['abc123']);
    expect(sessions, hasLength(1));
    expect(handler.lastSession?.userId, 'user-1');
    expect(handler.isAttached, isTrue);
  });

  test('a sign-in link with token_hash is verified through OTP', () async {
    await handler.start();

    deepLinks.emit(
      Uri.parse('kiln-auth://auth-callback?token_hash=hash-1&type=signup'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(gateway.verifiedTokenHashes, ['hash-1']);
    expect(gateway.verifiedTypes, ['signup']);
    expect(sessions, hasLength(1));
  });

  test('parameters in the fragment are also read', () async {
    await handler.start();

    deepLinks.emit(Uri.parse('kiln-auth://auth-callback#code=fragment-code'));
    await Future<void>.delayed(Duration.zero);

    expect(gateway.exchangedCodes, ['fragment-code']);
  });

  test('a link with no auth parameters is ignored', () async {
    await handler.start();

    deepLinks.emit(Uri.parse('kiln-auth://auth-callback?foo=bar'));
    await Future<void>.delayed(Duration.zero);

    expect(gateway.exchangedCodes, isEmpty);
    expect(gateway.verifiedTokenHashes, isEmpty);
    expect(sessions, isEmpty);
  });

  test('Supabase errors are reported through the failures stream', () async {
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

  test('dispose stops listening for new links', () async {
    await handler.start();
    await handler.dispose();

    deepLinks.emit(Uri.parse('kiln-auth://auth-callback?code=late'));
    await Future<void>.delayed(Duration.zero);

    expect(handler.isAttached, isFalse);
    expect(gateway.exchangedCodes, isEmpty);
  });

  test('without DeepLinks the handler attaches no subscription', () async {
    final detached = SupabaseLinkHandler(gateway: gateway);

    await detached.start();

    expect(detached.isAttached, isFalse);
    await detached.dispose();
  });
}
