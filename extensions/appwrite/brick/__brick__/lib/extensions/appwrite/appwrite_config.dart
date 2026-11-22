import 'package:flutter/foundation.dart';
import 'package:kiln_core/kiln_core.dart';

/// Appwrite connection settings rendered from the install prompts.
final class AppwriteConfig {
  const AppwriteConfig({
    this.endpoint = 'https://cloud.appwrite.io/v1',
    this.projectId = 'kiln_demo',
    this.databaseId = 'kiln',
    this.bucketId = 'kiln_files',
    this.oAuthRedirectUrl,
  });

  /// Values the Kiln installer writes into the application.
  static const defaults = AppwriteConfig(
    endpoint: '{{{endpoint}}}',
    projectId: '{{{project_id}}}',
    databaseId: '{{{database_id}}}',
    bucketId: '{{{bucket_id}}}',
  );

  /// Base URL of the Appwrite API, for example `https://cloud.appwrite.io/v1`.
  final String endpoint;

  /// Appwrite project that owns the database and bucket.
  final String projectId;

  /// Database that backs [RemoteDatabase].
  final String databaseId;

  /// Bucket that backs [FileStorage].
  final String bucketId;

  /// Web-only override for a subdirectory deployment or custom callback page.
  /// It must use the application's origin. Native login uses the SDK default.
  final String? oAuthRedirectUrl;

  Uri get endpointUri => Uri.parse(endpoint);

  /// Whether the endpoint uses cleartext http, as self-hosted Appwrite often does.
  bool get isInsecureTransport =>
      Uri.tryParse(endpoint)?.isScheme('http') ?? false;

  /// Web callback page, or the native scheme used to validate callback setup.
  /// The native launcher omits redirect overrides when calling the SDK so the
  /// server's default redirect includes the session credentials.
  String get oAuthSuccessUrl =>
      oAuthRedirectUrl ??
      (kIsWeb
          ? Uri.base.resolve('/kiln_appwrite_auth.html').toString()
          : 'appwrite-callback-$projectId://');

  /// Rejects values the Appwrite client cannot be built from.
  void validate() {
    final uri = Uri.tryParse(endpoint);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      throw Failure(
        code: FailureCode.configurationInvalid,
        message: 'Appwrite endpoint "$endpoint" is not an absolute URL.',
        kind: FailureKind.configuration,
        details: <String, Object?>{'endpoint': endpoint},
      );
    }
    if (projectId.trim().isEmpty) {
      throw const Failure(
        code: FailureCode.configurationMissing,
        message: 'Appwrite project id is required.',
        kind: FailureKind.configuration,
      );
    }
    if (databaseId.trim().isEmpty) {
      throw const Failure(
        code: FailureCode.configurationMissing,
        message: 'Appwrite database id is required.',
        kind: FailureKind.configuration,
      );
    }
    if (bucketId.trim().isEmpty) {
      throw const Failure(
        code: FailureCode.configurationMissing,
        message: 'Appwrite bucket id is required.',
        kind: FailureKind.configuration,
      );
    }
  }
}
