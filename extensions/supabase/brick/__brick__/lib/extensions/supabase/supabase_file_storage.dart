// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'supabase_failure_mapper.dart';
import 'supabase_storage_gateway.dart';

/// [FileStorage] implementation on top of Supabase Storage.
///
/// All files live in one bucket ([SupabaseStorageGateway]) and `url()` always
/// returns a signed link, never a public one.
final class SupabaseFileStorage implements FileStorage {
  SupabaseFileStorage({
    required SupabaseStorageGateway gateway,
    this.signedUrlLifetime = const Duration(hours: 1),
  }) : _gateway = gateway;

  final SupabaseStorageGateway _gateway;

  /// Default lifetime of links returned by [url].
  final Duration signedUrlLifetime;

  static final RegExp _pathPattern = RegExp(r'^[A-Za-z0-9!_.*()/ -]+$');

  @override
  Future<StoredFile> upload(
    FileUpload file, {
    ProgressCallback? onProgress,
  }) async {
    _validatePath(file.path);
    var reported = 0.0;
    await _call(
      () => _gateway.upload(
        file.path,
        file.bytes,
        contentType: file.contentType,
        metadata: file.metadata,
        onProgress: onProgress == null
            ? null
            : (progress) {
                reported = progress;
                onProgress(progress);
              },
      ),
      FailureCode.fileUploadFailed,
    );
    if (onProgress != null && reported < 1) {
      onProgress(1);
    }
    return StoredFile(
      path: file.path,
      size: file.size,
      contentType: file.contentType,
    );
  }

  @override
  Future<List<int>> download(
    String path, {
    ProgressCallback? onProgress,
  }) async {
    _validatePath(path);
    return _call(
      () => _gateway.download(path, onProgress: onProgress),
      FailureCode.fileDownloadFailed,
    );
  }

  @override
  Future<Uri> url(String path, {Duration? expiresIn}) async {
    _validatePath(path);
    final lifetime = expiresIn ?? signedUrlLifetime;
    if (lifetime <= Duration.zero) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'The link lifetime must be greater than zero.',
        kind: FailureKind.validation,
      );
    }
    return _call(
      () => _gateway.createSignedUrl(path, lifetime),
      FailureCode.fileDownloadFailed,
    );
  }

  @override
  Future<void> delete(String path) async {
    _validatePath(path);
    return _call(() => _gateway.delete(path), FailureCode.fileDeleteFailed);
  }

  void _validatePath(String path) {
    if (path.trim().isEmpty || path.startsWith('/') || path.contains('..')) {
      throw Failure(
        code: FailureCode.validationInvalidInput,
        message: 'The file path "$path" is not valid.',
        kind: FailureKind.validation,
      );
    }
    if (!_pathPattern.hasMatch(path)) {
      throw Failure(
        code: FailureCode.validationInvalidInput,
        message:
            'The file path may only contain letters, digits, and supported separators.',
        kind: FailureKind.validation,
      );
    }
  }

  Future<T> _call<T>(
    Future<T> Function() action,
    FailureCode fallbackCode,
  ) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(
        error,
        stackTrace: stackTrace,
        fallbackCode: fallbackCode,
        fallbackKind: FailureKind.storage,
      );
    }
  }
}
