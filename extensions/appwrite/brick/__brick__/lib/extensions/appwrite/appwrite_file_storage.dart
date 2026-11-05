import 'package:kiln_core/kiln_core.dart';

import 'appwrite_failure_mapper.dart';
import 'appwrite_storage_gateway.dart';

/// [FileStorage] on top of the Appwrite Storage service.
final class AppwriteFileStorage implements FileStorage {
  AppwriteFileStorage({
    required this.gateway,
    AppwriteFailureMapper failureMapper = const AppwriteFailureMapper(),
  }) : _failures = failureMapper;

  final AppwriteStorageGateway gateway;
  final AppwriteFailureMapper _failures;

  @override
  Future<StoredFile> upload(FileUpload file, {ProgressCallback? onProgress}) {
    return _guard(() async {
      _requirePath(file.path);
      final stored = await gateway.upload(
        path: file.path,
        bytes: file.bytes,
        contentType: file.contentType,
        onProgress: onProgress,
      );
      onProgress?.call(1);
      return stored;
    });
  }

  @override
  Future<List<int>> download(String path, {ProgressCallback? onProgress}) {
    return _guard(() async {
      _requirePath(path);
      final bytes = await gateway.download(path, onProgress: onProgress);
      onProgress?.call(1);
      return bytes;
    });
  }

  @override
  Future<Uri> url(String path, {Duration? expiresIn}) {
    return _guard(() {
      _requirePath(path);
      return gateway.url(path);
    });
  }

  @override
  Future<void> delete(String path) {
    return _guard(() {
      _requirePath(path);
      return gateway.delete(path);
    });
  }

  void _requirePath(String path) {
    if (path.trim().isEmpty) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'A file path is required.',
        kind: FailureKind.validation,
      );
    }
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on Object catch (error, stackTrace) {
      throw _failures.map(
        error,
        scope: AppwriteFailureScope.storage,
        stackTrace: stackTrace,
      );
    }
  }
}
