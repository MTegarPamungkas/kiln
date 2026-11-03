import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/social_login/social_login_failure_mapper.dart';

void main() {
  test('maps cancellation codes', () {
    final failure = mapSocialLoginError(
      PlatformException(code: 'theUserCanceledTheSignInFlow'),
    );

    expect(failure.code, FailureCode.authCancelled);
    expect(failure.kind, FailureKind.cancelled);
  });

  test('maps network failures', () {
    final failure = mapSocialLoginError(
      PlatformException(code: 'networkError'),
    );

    expect(failure.code, FailureCode.networkUnreachable);
    expect(failure.isRetryable, isTrue);
  });

  test('maps other provider errors', () {
    final failure = mapSocialLoginError(
      PlatformException(code: 'unknown', message: 'Kunci salah'),
    );

    expect(failure.code, FailureCode.authProviderDisabled);
    expect(failure.message, 'Kunci salah');
  });

  test('keeps an existing Failure', () {
    const original = Failure(
      code: FailureCode.authProviderDisabled,
      message: 'off',
    );

    expect(mapSocialLoginError(original), same(original));
  });
}
