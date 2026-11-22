import 'dart:async';

import 'package:flutter/services.dart';

/// A browser popup owned by one OAuth attempt.
abstract interface class AppwriteOAuthPopup {
  bool get isClosed;
  Stream<Uri> get callbacks;
  void close();
}

/// Owns popup cancellation and callback correlation independently of the DOM.
final class AppwriteOAuthPopupFlow {
  AppwriteOAuthPopupFlow({
    required this.open,
    required this.createAttemptId,
    this.pollInterval = const Duration(milliseconds: 200),
    this.timeout = const Duration(minutes: 5),
  });

  final AppwriteOAuthPopup? Function(Uri url, Uri callback) open;
  final String Function() createAttemptId;
  final Duration pollInterval;
  final Duration timeout;
  void Function()? _cancel;

  void cancel() => _cancel?.call();

  Future<void> run(
    Uri authorization,
    Uri callback, {
    Uri? failureCallback,
  }) async {
    cancel();
    final attempt = createAttemptId();
    final tagged = callback.replace(
      queryParameters: {
        ...callback.queryParameters,
        'kiln_oauth_attempt': attempt,
      },
    );
    final failure = failureCallback ?? callback;
    final taggedFailure = failure.replace(
      queryParameters: {
        ...failure.queryParameters,
        'kiln_oauth_attempt': attempt,
      },
    );
    final url = authorization.replace(
      queryParameters: {
        ...authorization.queryParameters,
        'success': tagged.toString(),
        'failure': taggedFailure.toString(),
      },
    );
    final popup = open(url, tagged);
    if (popup == null) {
      throw PlatformException(
        code: 'POPUP_BLOCKED',
        message: 'Allow popups for this application and try signing in again.',
      );
    }
    final result = Completer<void>();
    void abort() {
      if (!result.isCompleted) {
        result.completeError(
          PlatformException(
            code: 'CANCELED',
            message: 'OAuth sign-in was cancelled.',
          ),
        );
      }
      popup.close();
    }

    _cancel = abort;
    final listener = popup.callbacks.listen(
      (uri) {
        if (result.isCompleted ||
            (uri.scheme != 'http' && uri.scheme != 'https') ||
            !uri.hasAuthority ||
            uri.origin != callback.origin ||
            (uri.path != callback.path && uri.path != failure.path) ||
            uri.queryParameters['kiln_oauth_attempt'] != attempt) {
          return;
        }
        if (uri.queryParameters.containsKey('error') ||
            uri.path != callback.path) {
          if (uri.queryParameters['error'] == 'access_denied') {
            abort();
          } else {
            result.completeError(
              PlatformException(
                code: 'OAUTH_FAILED',
                message:
                    'The OAuth provider returned an error. Please try again.',
              ),
            );
          }
        } else {
          result.complete();
        }
      },
      onError: (Object error, StackTrace stack) {
        if (!result.isCompleted) result.completeError(error, stack);
      },
    );
    final polling = Timer.periodic(pollInterval, (_) {
      if (popup.isClosed) abort();
    });
    final deadline = Timer(timeout, abort);
    try {
      await result.future;
    } finally {
      if (identical(_cancel, abort)) _cancel = null;
      polling.cancel();
      deadline.cancel();
      await listener.cancel();
      popup.close();
    }
  }
}
