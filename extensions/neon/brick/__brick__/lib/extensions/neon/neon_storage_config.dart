// ignore_for_file: prefer_initializing_formals

import 'package:kiln_core/kiln_core.dart';

import 'neon_s3_signer.dart';

/// Typed configuration for Neon Object Storage (S3-compatible).
///
/// [endpoint] is the branch storage host, for example
/// `https://{branch}.storage.c-{region}.aws.neon.tech`. Requests use path-style
/// addressing: `endpoint/bucket/key`. [accessKeyId] is a Neon token id and
/// [secretAccessKey] is the matching S3 secret; both are shipped to the client
/// in this direct-from-app setup, so scope them to one bucket with least
/// privilege.
final class NeonStorageConfig {
  const NeonStorageConfig({
    required this.endpoint,
    required this.bucket,
    required this.region,
    required this.accessKeyId,
    required this.secretAccessKey,
    this.signedUrlLifetime = const Duration(hours: 1),
  });

  /// Values rendered from the extension prompts.
  static const NeonStorageConfig defaults = NeonStorageConfig(
    endpoint: '{{{s3_endpoint}}}',
    bucket: '{{{s3_bucket}}}',
    region: '{{{s3_region}}}',
    accessKeyId: '{{{s3_access_key_id}}}',
    secretAccessKey: '{{{s3_secret_access_key}}}',
  );

  static final RegExp _bucketPattern = RegExp(r'^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$');

  final String endpoint;
  final String bucket;
  final String region;
  final String accessKeyId;
  final String secretAccessKey;

  /// Default lifetime of the link returned by `FileStorage.url`.
  final Duration signedUrlLifetime;

  bool get isInsecureTransport => Uri.tryParse(endpoint)?.isScheme('http') ?? false;

  /// The base endpoint with any trailing slash removed.
  String get normalizedEndpoint =>
      endpoint.endsWith('/') ? endpoint.substring(0, endpoint.length - 1) : endpoint;

  /// Path-style URL for [key] (`endpoint/bucket/key`).
  Uri objectUri(String key) {
    final encoded = NeonS3Signer.encodeObjectPath(key);
    return Uri.parse('$normalizedEndpoint/$bucket/$encoded');
  }

  /// Validates the configuration. The secret never appears in a message.
  Failure? validate() {
    final uri = Uri.tryParse(endpoint);
    if (uri == null ||
        uri.host.isEmpty ||
        !(uri.isScheme('http') || uri.isScheme('https'))) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message: 'The Neon Object Storage endpoint must be a complete http or https address.',
        kind: FailureKind.configuration,
      );
    }
    if (!_bucketPattern.hasMatch(bucket)) {
      return Failure(
        code: FailureCode.configurationInvalid,
        message: 'Bucket "$bucket" is not a valid S3 bucket name.',
        kind: FailureKind.configuration,
      );
    }
    if (region.trim().isEmpty) {
      return const Failure(
        code: FailureCode.configurationMissing,
        message: 'The Neon Object Storage region is not set.',
        kind: FailureKind.configuration,
      );
    }
    if (accessKeyId.trim().isEmpty) {
      return const Failure(
        code: FailureCode.configurationMissing,
        message: 'The Neon Object Storage access key id is not set.',
        kind: FailureKind.configuration,
      );
    }
    if (secretAccessKey.trim().isEmpty) {
      return const Failure(
        code: FailureCode.configurationMissing,
        message: 'The Neon Object Storage secret access key is not set.',
        kind: FailureKind.configuration,
      );
    }
    if (signedUrlLifetime <= Duration.zero) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message: 'The signed URL lifetime must be greater than zero.',
        kind: FailureKind.configuration,
      );
    }
    return null;
  }

  NeonStorageConfig copyWith({
    String? endpoint,
    String? bucket,
    String? region,
    String? accessKeyId,
    String? secretAccessKey,
    Duration? signedUrlLifetime,
  }) {
    return NeonStorageConfig(
      endpoint: endpoint ?? this.endpoint,
      bucket: bucket ?? this.bucket,
      region: region ?? this.region,
      accessKeyId: accessKeyId ?? this.accessKeyId,
      secretAccessKey: secretAccessKey ?? this.secretAccessKey,
      signedUrlLifetime: signedUrlLifetime ?? this.signedUrlLifetime,
    );
  }
}
