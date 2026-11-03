import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/image_picker/media_failure_mapper.dart';

void main() {
  test('maps denied access to a permission failure', () {
    final failure = mapMediaError(
      PlatformException(code: 'camera_access_denied', message: 'No camera'),
    );

    expect(failure.code, FailureCode.mediaPermissionDenied);
    expect(failure.kind, FailureKind.permission);
  });

  test('maps cancellation', () {
    final failure = mapMediaError(PlatformException(code: 'cancelled'));

    expect(failure.code, FailureCode.mediaCancelled);
    expect(failure.kind, FailureKind.cancelled);
  });

  test('maps other plugin errors to unavailable', () {
    final failure = mapMediaError(PlatformException(code: 'unknown'));

    expect(failure.code, FailureCode.mediaUnavailable);
    expect(failure.kind, FailureKind.media);
  });

  test('keeps an existing Failure', () {
    const original = Failure(
      code: FailureCode.mediaInvalid,
      message: 'too big',
      kind: FailureKind.validation,
    );

    expect(mapMediaError(original), same(original));
  });
}
