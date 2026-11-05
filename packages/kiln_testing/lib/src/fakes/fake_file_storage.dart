import 'package:kiln_core/kiln_core.dart';

/// [FileStorage] that keeps uploaded bytes in memory.
final class FakeFileStorage implements FileStorage {
  final Map<String, List<int>> files = <String, List<int>>{};
  final List<String> deleted = <String>[];
  Failure? failure;

  Future<void> _maybeFail() async {
    final programmedFailure = failure;
    if (programmedFailure != null) {
      throw programmedFailure;
    }
  }

  @override
  Future<StoredFile> upload(
    FileUpload file, {
    ProgressCallback? onProgress,
  }) async {
    await _maybeFail();
    files[file.path] = List<int>.of(file.bytes);
    onProgress?.call(1);
    return StoredFile(
      path: file.path,
      url: 'https://files.kiln.dev/${file.path}',
      size: file.bytes.length,
      contentType: file.contentType,
    );
  }

  @override
  Future<List<int>> download(
    String path, {
    ProgressCallback? onProgress,
  }) async {
    await _maybeFail();
    final bytes = files[path];
    if (bytes == null) {
      throw const Failure(
        code: FailureCode.fileNotFound,
        message: 'File not found',
        kind: FailureKind.file,
      );
    }
    onProgress?.call(1);
    return List<int>.of(bytes);
  }

  @override
  Future<Uri> url(String path, {Duration? expiresIn}) async {
    await _maybeFail();
    return Uri.parse('https://files.kiln.dev/$path');
  }

  @override
  Future<void> delete(String path) async {
    await _maybeFail();
    if (files.remove(path) == null) {
      throw const Failure(
        code: FailureCode.fileNotFound,
        message: 'File not found',
        kind: FailureKind.file,
      );
    }
    deleted.add(path);
  }
}
