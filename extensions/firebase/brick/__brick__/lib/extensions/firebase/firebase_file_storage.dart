import 'package:kiln_core/kiln_core.dart';

import 'firebase_failure_mapper.dart';
import 'firebase_storage_gateway.dart';

/// [FileStorage] backed by a [FirebaseStorageGateway].
final class FirebaseFileStorage implements FileStorage {
  const FirebaseFileStorage({
    required this.gateway,
    this.failureMapper = mapFirebaseError,
  });

  final FirebaseStorageGateway gateway;
  final FirebaseFailureMapper failureMapper;

  @override
  Future<StoredFile> upload(
    FileUpload file, {
    ProgressCallback? onProgress,
  }) async {
    _validatePath(file.path);
    final tracker = _ProgressTracker(onProgress);

    try {
      final stored = await gateway.upload(
        file,
        onProgress: onProgress == null ? null : tracker.report,
      );
      tracker.complete();
      return StoredFile(
        path: stored.path.isEmpty ? file.path : stored.path,
        url: stored.url,
        size: stored.size ?? file.size,
        contentType: stored.contentType ?? file.contentType,
      );
    } catch (error, stackTrace) {
      throw _mapError(
        error,
        stackTrace,
        code: FailureCode.fileUploadFailed,
        message: 'Failed to upload the file to Cloud Storage.',
      );
    }
  }

  @override
  Future<List<int>> download(
    String path, {
    ProgressCallback? onProgress,
  }) async {
    _validatePath(path);
    final tracker = _ProgressTracker(onProgress);
    try {
      final bytes = await gateway.download(
        path,
        onProgress: onProgress == null ? null : tracker.report,
      );
      tracker.complete();
      return bytes;
    } catch (error, stackTrace) {
      throw _mapError(
        error,
        stackTrace,
        code: FailureCode.fileDownloadFailed,
        message: 'Failed to download the file from Cloud Storage.',
      );
    }
  }

  @override
  Future<Uri> url(String path, {Duration? expiresIn}) async {
    _validatePath(path);
    try {
      // Firebase download URLs do not expire; expiresIn is kept for contracts
      // backed by storage providers that issue signed links.
      return await gateway.url(path);
    } catch (error, stackTrace) {
      throw _mapError(
        error,
        stackTrace,
        code: FailureCode.fileNotFound,
        message: 'The file was not found in Cloud Storage.',
      );
    }
  }

  @override
  Future<void> delete(String path) async {
    _validatePath(path);
    try {
      await gateway.delete(path);
    } catch (error, stackTrace) {
      throw _mapError(
        error,
        stackTrace,
        code: FailureCode.fileDeleteFailed,
        message: 'Failed to delete the file from Cloud Storage.',
      );
    }
  }

  Failure _mapError(
    Object error,
    StackTrace stackTrace, {
    required FailureCode code,
    required String message,
  }) {
    final failure = failureMapper(error, stackTrace);
    if (failure.code == FailureCode.unexpected) {
      return Failure(
        code: code,
        message: message,
        kind: FailureKind.file,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return failure;
  }

  void _validatePath(String path) {
    if (path.trim().isEmpty) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'The file path cannot be empty.',
        kind: FailureKind.validation,
      );
    }
  }
}

/// Clamps progress, drops regressions, and guarantees a final 1.0 event.
final class _ProgressTracker {
  _ProgressTracker(this.onProgress);

  final ProgressCallback? onProgress;
  double _last = 0;

  void report(double value) {
    final progress = value.clamp(0.0, 1.0).toDouble();
    if (progress <= _last && progress < 1) {
      return;
    }
    _last = progress;
    onProgress?.call(progress);
  }

  void complete() {
    if (onProgress != null && _last < 1) {
      report(1);
    }
  }
}
