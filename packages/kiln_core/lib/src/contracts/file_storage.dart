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

  Future<Uri> url(String path, {Duration? expiresIn});

  Future<void> delete(String path);
}
