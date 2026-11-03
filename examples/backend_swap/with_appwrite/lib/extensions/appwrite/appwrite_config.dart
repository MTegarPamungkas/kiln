import 'package:kiln_core/kiln_core.dart';

/// Appwrite connection settings rendered from the install prompts.
final class AppwriteConfig {
  const AppwriteConfig({
    this.endpoint = 'https://cloud.appwrite.io/v1',
    this.projectId = 'kiln_demo',
    this.databaseId = 'kiln',
    this.bucketId = 'kiln_files',
  });

  /// Values the Kiln installer writes into the application.
  static const defaults = AppwriteConfig(
    endpoint: 'https://cloud.appwrite.io/v1',
    projectId: 'kiln_demo',
    databaseId: 'kiln',
    bucketId: 'kiln_files',
  );

  /// Base URL of the Appwrite API, for example `https://cloud.appwrite.io/v1`.
  final String endpoint;

  /// Appwrite project that owns the database and bucket.
  final String projectId;

  /// Database that backs [RemoteDatabase].
  final String databaseId;

  /// Bucket that backs [FileStorage].
  final String bucketId;

  Uri get endpointUri => Uri.parse(endpoint);

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
