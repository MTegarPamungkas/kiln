// ignore_for_file: prefer_initializing_formals

import 'package:kiln_core/kiln_core.dart';

import 'supabase_failure_mapper.dart';
import 'supabase_gateway.dart';

/// [TokenProvider] that reads the access token from the active Supabase session.
///
/// The token always comes from the session, so Supabase auto refresh and
/// `forceRefresh` share the same path.
final class SupabaseTokenProvider implements TokenProvider {
  SupabaseTokenProvider({required SupabaseGateway gateway})
    : _gateway = gateway;

  final SupabaseGateway _gateway;

  @override
  Future<String?> accessToken({bool forceRefresh = false}) async {
    try {
      final token = await _gateway.accessToken(forceRefresh: forceRefresh);
      return token == null || token.isEmpty ? null : token;
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(
        error,
        stackTrace: stackTrace,
        fallbackCode: FailureCode.authSessionExpired,
        fallbackKind: FailureKind.session,
      );
    }
  }

  /// Ends the local session because the session is the only token source.
  @override
  Future<void> clear() async {
    try {
      await _gateway.signOut();
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(
        error,
        stackTrace: stackTrace,
        fallbackCode: FailureCode.authSessionExpired,
        fallbackKind: FailureKind.session,
      );
    }
  }
}
