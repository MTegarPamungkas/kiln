import 'package:dio/dio.dart' hide ProgressCallback;
import 'package:kiln_core/kiln_core.dart';

import 'dio_client.dart';
import 'dio_failure_mapper.dart';

/// Downloads a file to [savePath] and reports receive progress.
Future<void> downloadFile(
  DioClient client, {
  required String path,
  required String savePath,
  ProgressCallback? onProgress,
}) async {
  try {
    await client.dio.download(
      path,
      savePath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress?.call(received / total);
        }
      },
    );
  } on DioException catch (error) {
    throw mapDioException(error);
  }
}
