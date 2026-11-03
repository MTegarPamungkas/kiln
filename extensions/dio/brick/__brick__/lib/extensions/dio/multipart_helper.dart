import 'package:dio/dio.dart' hide ProgressCallback;
import 'package:kiln_core/kiln_core.dart';

import 'dio_client.dart';
import 'dio_failure_mapper.dart';

/// Uploads one file as multipart and reports send progress.
Future<HttpResponse> uploadMultipart(
  DioClient client, {
  required String path,
  required String field,
  required String filename,
  required List<int> bytes,
  Map<String, String> fields = const <String, String>{},
  Map<String, String> headers = const <String, String>{},
  ProgressCallback? onProgress,
}) async {
  final form = FormData.fromMap(<String, Object?>{
    ...fields,
    field: MultipartFile.fromBytes(bytes, filename: filename),
  });

  try {
    final response = await client.dio.post<Object?>(
      path,
      data: form,
      options: Options(headers: headers),
      onSendProgress: (sent, total) {
        if (total > 0) {
          onProgress?.call(sent / total);
        }
      },
    );
    return HttpResponse(
      statusCode: response.statusCode ?? 0,
      data: response.data,
      headers: <String, List<String>>{
        for (final entry in response.headers.map.entries)
          entry.key: entry.value,
      },
    );
  } on DioException catch (error) {
    throw mapDioException(error);
  }
}
