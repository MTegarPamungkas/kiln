import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:web/web.dart' as web;

import 'appwrite_oauth_popup_flow.dart';

final _flows = Expando<AppwriteOAuthPopupFlow>();

Future<void> launchAppwriteOAuth(
  Account account, {
  required OAuthProvider provider,
  required String successUrl,
  String? failureUrl,
}) async {
  final callback = Uri.parse(successUrl);
  final failure = failureUrl == null ? callback : Uri.parse(failureUrl);
  if (callback.origin != Uri.base.origin || failure.origin != Uri.base.origin) {
    throw ArgumentError('OAuth callback must use the application origin.');
  }
  final flow = _flows[account] ??= AppwriteOAuthPopupFlow(
    open: _open,
    createAttemptId: () {
      final random = Random.secure();
      return base64UrlEncode(
        List<int>.generate(24, (_) => random.nextInt(256)),
      );
    },
  );
  final endpoint = Uri.parse(account.client.endPoint);
  await flow.run(
    endpoint.replace(
      path: '${endpoint.path}/account/sessions/oauth2/${provider.value}',
      queryParameters: {'project': account.client.config['project']!},
    ),
    callback,
    failureCallback: failure,
  );
}

void cancelAppwriteOAuth(Account account) => _flows[account]?.cancel();

AppwriteOAuthPopup? _open(Uri url, Uri callback) {
  final popup = web.window.open(
    url.toString(),
    '_blank',
    'popup,width=520,height=700',
  );
  return popup == null ? null : _BrowserPopup(popup, callback);
}

final class _BrowserPopup implements AppwriteOAuthPopup {
  _BrowserPopup(this.window, Uri callback) {
    _listener = ((web.MessageEvent event) {
      if (event.origin != callback.origin || event.source != window) return;
      final data = event.data.dartify();
      if (data is! Map) return;
      final value = data['kiln-appwrite-oauth'];
      if (value is! String) return;
      final uri = Uri.tryParse(value);
      if (uri != null && !_callbacks.isClosed) _callbacks.add(uri);
    }).toJS;
    web.window.addEventListener('message', _listener);
  }

  final web.Window window;
  final _callbacks = StreamController<Uri>.broadcast(sync: true);
  late final JSFunction _listener;
  bool _closed = false;
  @override
  bool get isClosed => window.closed;
  @override
  Stream<Uri> get callbacks => _callbacks.stream;
  @override
  void close() {
    if (_closed) return;
    _closed = true;
    web.window.removeEventListener('message', _listener);
    window.close();
    unawaited(_callbacks.close());
  }
}
