import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_oauth_popup_flow.dart';

final class Popup implements AppwriteOAuthPopup {
  final messages = StreamController<Uri>.broadcast(sync: true);
  bool closed = false;
  @override
  bool get isClosed => closed;
  @override
  Stream<Uri> get callbacks => messages.stream;
  @override
  void close() => closed = true;
}

void main() {
  final authorization = Uri.parse(
    'https://api.test/v1/account/sessions/oauth2/google?project=p',
  );
  final callback = Uri.parse('https://app.test/kiln_appwrite_auth.html');
  Matcher cancelled() =>
      isA<PlatformException>().having((e) => e.code, 'code', 'CANCELED');

  test(
    'closing popup cancels promptly and a new attempt can succeed',
    () async {
      final popups = <Popup>[];
      final callbacks = <Uri>[];
      var sequence = 0;
      final flow = AppwriteOAuthPopupFlow(
        open: (url, tagged) {
          expect(Uri.parse(url.queryParameters['success']!), tagged);
          expect(Uri.parse(url.queryParameters['failure']!), tagged);
          callbacks.add(tagged);
          final popup = Popup();
          popups.add(popup);
          return popup;
        },
        createAttemptId: () => '${++sequence}',
        pollInterval: const Duration(milliseconds: 1),
      );
      final first = flow.run(authorization, callback);
      final firstResult = expectLater(first, throwsA(cancelled()));
      popups.first.closed = true;
      await firstResult;
      expect(popups.first.messages.hasListener, isFalse);
      final retry = flow.run(authorization, callback);
      popups.last.messages.add(callbacks.last);
      await retry;
      expect(popups.last.closed, isTrue);
      expect(popups.last.messages.hasListener, isFalse);
      for (final popup in popups) {
        await popup.messages.close();
      }
    },
  );

  test(
    'replacement closes old popup and rejects stale callback correlation',
    () async {
      final popups = <Popup>[];
      final callbacks = <Uri>[];
      var sequence = 0;
      final flow = AppwriteOAuthPopupFlow(
        open: (_, tagged) {
          callbacks.add(tagged);
          final popup = Popup();
          popups.add(popup);
          return popup;
        },
        createAttemptId: () => '${++sequence}',
      );
      final first = flow.run(authorization, callback);
      final oldResult = expectLater(first, throwsA(cancelled()));
      var completed = false;
      final second = flow
          .run(authorization, callback)
          .then((_) => completed = true);
      await oldResult;
      expect(popups.first.closed, isTrue);
      popups.last.messages.add(callbacks.first);
    popups.last.messages.add(Uri.parse('/relative-callback'));
    popups.last.messages.add(Uri.parse('javascript:invalid'));
      popups.last.messages.add(callbacks.last.replace(host: 'other.test'));
      popups.last.messages.add(callbacks.last.replace(path: '/other'));
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      popups.last.messages.add(callbacks.last);
      await second;
      expect(completed, isTrue);
      for (final popup in popups) {
        await popup.messages.close();
      }
    },
  );

  test(
    'deadline and explicit cancellation close popup and detach listeners',
    () async {
      for (final explicit in [false, true]) {
        final popup = Popup();
        final flow = AppwriteOAuthPopupFlow(
          open: (_, _) => popup,
          createAttemptId: () => 'attempt',
          timeout: const Duration(milliseconds: 5),
        );
        final pending = flow.run(authorization, callback);
        final result = expectLater(pending, throwsA(cancelled()));
        if (explicit) flow.cancel();
        await result;
        expect(popup.closed, isTrue);
        expect(popup.messages.hasListener, isFalse);
        await popup.messages.close();
      }
    },
  );

  test('blocked popup reports a recoverable error', () async {
    final flow = AppwriteOAuthPopupFlow(
      open: (_, _) => null,
      createAttemptId: () => 'attempt',
    );
    await expectLater(
      flow.run(authorization, callback),
      throwsA(
        isA<PlatformException>().having((e) => e.code, 'code', 'POPUP_BLOCKED'),
      ),
    );
  });

  test(
    'provider failure preserves its callback path and reports an error',
    () async {
      final popup = Popup();
      late Uri failure;
      final flow = AppwriteOAuthPopupFlow(
        open: (url, _) {
          failure = Uri.parse(url.queryParameters['failure']!);
          expect(failure.path, '/oauth_failure.html');
          return popup;
        },
        createAttemptId: () => 'attempt',
      );
      final pending = flow.run(
        authorization,
        callback,
        failureCallback: callback.replace(path: '/oauth_failure.html'),
      );
      final result = expectLater(
        pending,
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'OAUTH_FAILED',
          ),
        ),
      );
      popup.messages.add(failure);
      await result;
      expect(popup.closed, isTrue);
      await popup.messages.close();
    },
  );
}
