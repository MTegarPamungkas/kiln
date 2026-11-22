/// Payload for one file upload.
final class FileUpload {
  const FileUpload({
    required this.path,
    required this.bytes,
    this.contentType,
    this.metadata = const <String, String>{},
  });

  final String path;
  final List<int> bytes;
  final String? contentType;
  final Map<String, String> metadata;

  int get size => bytes.length;
}

/// A file that exists in a remote bucket.
final class StoredFile {
  const StoredFile({required this.path, this.url, this.size, this.contentType});

  final String path;
  final String? url;
  final int? size;
  final String? contentType;
}

typedef ProgressCallback = void Function(double progress);

/// Uploads, downloads, links, and deletes files in a remote bucket.
abstract interface class FileStorage {
  Future<StoredFile> upload(FileUpload file, {ProgressCallback? onProgress});

  Future<List<int>> download(String path, {ProgressCallback? onProgress});

  /// Returns a link to the file.
  ///
  /// [expiresIn] is a requested capability, not a hint. An implementation that
  /// can issue signed links must honor it (or fail with
  /// `validation.unsupported_value` when the requested lifetime is invalid).
  /// An implementation that can only return a permanent or public link must
  /// reject a non-null [expiresIn] with `validation.unsupported_value`; it must
  /// never silently return a permanent link when the caller asked for expiry.
  Future<Uri> url(String path, {Duration? expiresIn});

  Future<void> delete(String path);
}
