import 'dart:ui' show Rect;

import 'package:kiln_core/kiln_core.dart';
import 'package:share_plus/share_plus.dart';

import 'share_gateway.dart';

/// [ShareGateway] backed by share_plus.
final class SdkShareGateway implements ShareGateway {
  const SdkShareGateway();

  @override
  Future<ShareOutcome> share(
    ShareContent content, {
    ShareOrigin? origin,
  }) async {
    if ((content.text ?? '').trim().isEmpty && content.files.isEmpty) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'Nothing to share. Provide text or at least one file.',
        kind: FailureKind.validation,
      );
    }
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: content.text,
          subject: content.subject,
          files: content.files.isEmpty
              ? null
              : <XFile>[
                  for (final file in content.files)
                    XFile(file.path, mimeType: file.mimeType, name: file.name),
                ],
          sharePositionOrigin: origin == null
              ? null
              : Rect.fromLTWH(
                  origin.left,
                  origin.top,
                  origin.width,
                  origin.height,
                ),
        ),
      );
      return switch (result.status) {
        ShareResultStatus.success => ShareOutcome.shared,
        ShareResultStatus.dismissed => ShareOutcome.dismissed,
        ShareResultStatus.unavailable => ShareOutcome.unavailable,
      };
    } on Failure {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw Failure.from(
        error,
        code: FailureCode.unavailable,
        kind: FailureKind.unavailable,
        stackTrace: stackTrace,
      );
    }
  }
}
