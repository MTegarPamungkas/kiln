import 'package:kiln_core/kiln_core.dart';

/// Public configuration for a custom, JWT-authenticated presigning backend.
/// S3 credentials belong exclusively on that backend, never in the app.
final class NeonStorageConfig {
  const NeonStorageConfig({
    required this.signingUrl,
    required this.bucket,
    this.signedUrlLifetime = const Duration(minutes: 5),
  });

  static const NeonStorageConfig defaults = NeonStorageConfig(
    signingUrl: '{{{storage_signing_url}}}',
    bucket: '{{{s3_bucket}}}',
  );

  static const maxSignedUrlLifetime = Duration(minutes: 15);
  static final RegExp _bucketPattern = RegExp(r'^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$');

  final String signingUrl;
  final String bucket;
  final Duration signedUrlLifetime;

  bool get isInsecureTransport => Uri.tryParse(signingUrl)?.isScheme('http') ?? false;

  Failure? validate() {
    final uri = Uri.tryParse(signingUrl);
    final local = uri != null &&
        const {'localhost', '127.0.0.1', '::1', '[::1]'}.contains(uri.host);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        uri.hasQuery ||
        !(uri.isScheme('https') || (uri.isScheme('http') && local))) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message: 'The storage signing URL must be HTTPS (HTTP loopback is allowed for development), without credentials, query, or fragment.',
        kind: FailureKind.configuration,
      );
    }
    if (!_bucketPattern.hasMatch(bucket)) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message: 'The storage bucket name is invalid.',
        kind: FailureKind.configuration,
      );
    }
    if (!isValidLifetime(signedUrlLifetime)) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message: 'The signed URL lifetime must be whole seconds between 1 and 900.',
        kind: FailureKind.configuration,
      );
    }
    return null;
  }

  static bool isValidLifetime(Duration value) =>
      value >= const Duration(seconds: 1) &&
      value <= maxSignedUrlLifetime &&
      value.inMicroseconds % Duration.microsecondsPerSecond == 0;

  NeonStorageConfig copyWith({
    String? signingUrl,
    String? bucket,
    Duration? signedUrlLifetime,
  }) => NeonStorageConfig(
    signingUrl: signingUrl ?? this.signingUrl,
    bucket: bucket ?? this.bucket,
    signedUrlLifetime: signedUrlLifetime ?? this.signedUrlLifetime,
  );
}
