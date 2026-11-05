import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/deep_link/deep_link_failure_mapper.dart';

void main() {
  test('maps plugin errors to an unavailable deep link failure', () {
    final failure = mapDeepLinkError(
      PlatformException(code: 'unavailable', message: 'No handler'),
    );

    expect(failure.code, FailureCode.deepLinkUnavailable);
    expect(failure.kind, FailureKind.deepLink);
  });

  test('maps malformed links to an invalid deep link failure', () {
    final failure = mapDeepLinkError(const FormatException('bad uri'));

    expect(failure.code, FailureCode.deepLinkInvalid);
    expect(failure.kind, FailureKind.deepLink);
  });

  test('keeps an existing Failure', () {
    const original = Failure(
      code: FailureCode.deepLinkInvalid,
      message: 'ditolak',
      kind: FailureKind.deepLink,
    );

    expect(mapDeepLinkError(original), same(original));
  });
}
