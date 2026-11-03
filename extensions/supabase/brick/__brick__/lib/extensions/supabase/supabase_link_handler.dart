// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'supabase_failure_mapper.dart';
import 'supabase_gateway.dart';

/// Receives email confirmation, password reset, and OAuth callbacks from
/// [DeepLinks].
///
/// The handler reads the initial link, subscribes to the following links, and
/// calls `exchangeCodeForSession` (PKCE flow, `code` parameter) or `verifyOtp`
/// (`token_hash`/`token` together with `type`). The `DeepLinks` contract stays
/// owned by the `deep_link` extension, so [dispose] only removes the
/// subscription.
final class SupabaseLinkHandler {
  SupabaseLinkHandler({
    required SupabaseGateway gateway,
    DeepLinks? deepLinks,
    void Function(SupabaseSession session)? onSession,
  }) : _gateway = gateway,
       _deepLinks = deepLinks,
       _onSession = onSession;

  final SupabaseGateway _gateway;
  final DeepLinks? _deepLinks;
  final void Function(SupabaseSession session)? _onSession;

  final StreamController<Failure> _failures =
      StreamController<Failure>.broadcast(sync: true);
  StreamSubscription<Uri>? _subscription;
  Future<void> _pending = Future<void>.value();
  SupabaseSession? _lastSession;

  bool get isAttached => _subscription != null;

  /// Callback failures that cannot be thrown to the caller.
  Stream<Failure> get failures => _failures.stream;

  /// Last session produced by a callback, if any.
  SupabaseSession? get lastSession => _lastSession;

  /// Handles the initial link and starts listening for later links.
  ///
  /// Does nothing when [DeepLinks] is not installed.
  Future<void> start() async {
    final deepLinks = _deepLinks;
    if (deepLinks == null || _subscription != null) {
      return;
    }
    final initial = deepLinks.initialLink;
    if (initial != null) {
      await _handle(initial);
    }
    _subscription = deepLinks.links.listen((uri) {
      _pending = _pending.then((_) => _handle(uri));
    });
  }

  /// Handles one link; null means it is not a Supabase callback.
  Future<SupabaseSession?> handle(Uri uri) async {
    final parameters = _parametersOf(uri);
    final error = parameters['error_description'] ?? parameters['error'];
    if (error != null && error.isNotEmpty) {
      throw Failure(
        code: FailureCode.authUnauthorized,
        message: 'Callback Supabase gagal: $error',
        kind: FailureKind.authentication,
        details: <String, Object?>{
          if (parameters['error_code'] != null)
            'error_code': parameters['error_code'],
        },
      );
    }

    final code = parameters['code'];
    if (code != null && code.isNotEmpty) {
      final session = await _call(() => _gateway.exchangeCodeForSession(code));
      _complete(session);
      return session;
    }

    final tokenHash = parameters['token_hash'] ?? parameters['token'];
    final type = parameters['type'];
    if (tokenHash != null &&
        tokenHash.isNotEmpty &&
        type != null &&
        type.isNotEmpty) {
      final session = await _call(
        () => _gateway.verifyOtp(tokenHash: tokenHash, type: type),
      );
      _complete(session);
      return session;
    }

    return null;
  }

  /// Removes the subscription and closes the failure stream.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _failures.close();
  }

  Future<void> _handle(Uri uri) async {
    try {
      await handle(uri);
    } on Failure catch (failure) {
      _report(failure);
    } on Object catch (error, stackTrace) {
      _report(
        mapSupabaseError(
          error,
          stackTrace: stackTrace,
          fallbackCode: FailureCode.deepLinkInvalid,
          fallbackKind: FailureKind.deepLink,
        ),
      );
    }
  }

  void _complete(SupabaseSession session) {
    _lastSession = session;
    _onSession?.call(session);
  }

  void _report(Failure failure) {
    if (!_failures.isClosed) {
      _failures.add(failure);
    }
  }

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(
        error,
        stackTrace: stackTrace,
        fallbackCode: FailureCode.authSessionExpired,
        fallbackKind: FailureKind.session,
      );
    }
  }

  Map<String, String> _parametersOf(Uri uri) {
    final parameters = <String, String>{...uri.queryParameters};
    final fragment = uri.fragment;
    if (fragment.isNotEmpty) {
      try {
        parameters.addAll(Uri.splitQueryString(fragment));
      } on FormatException {
        // The fragment is not a query string; keep the existing parameters.
      }
    }
    return parameters;
  }
}
