import 'package:kiln_core/kiln_core.dart';

import 'appwrite_config.dart';

/// Validates the endpoint and identifiers needed by the Appwrite client.
final class AppwriteSupport {
  AppwriteSupport({required this.config});

  final AppwriteConfig config;

  SupportInfo get info {
    try {
      config.validate();
      return SupportInfo.supported(
        details: <String, Object?>{
          'endpoint': config.endpointUri.origin,
          'project': config.projectId,
          'database': config.databaseId,
          'insecure_http': config.isInsecureTransport,
        },
      );
    } on Failure catch (failure) {
      return SupportInfo.unsupported(
        SupportState.notConfigured,
        message: failure.message,
        details: <String, Object?>{'code': failure.code.value},
      );
    } on Object catch (error) {
      return SupportInfo.unsupported(
        SupportState.notConfigured,
        message: 'Appwrite configuration is invalid: $error',
        details: <String, Object?>{'error': '$error'},
      );
    }
  }
}
