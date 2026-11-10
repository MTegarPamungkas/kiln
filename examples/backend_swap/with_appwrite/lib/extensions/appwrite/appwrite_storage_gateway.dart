import 'dart:convert';
import 'dart:typed_data';

import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:kiln_core/kiln_core.dart';

import 'appwrite_config.dart';

/// Bucket operations that can be replaced with an in-memory fake.
abstract interface class AppwriteStorageGateway {
  Future<StoredFile> upload({
    required String path,
    required List<int> bytes,
    String? contentType,
    ProgressCallback? onProgress,
  });

  Future<List<int>> download(String path, {ProgressCallback? onProgress});

  Future<Uri> url(String path);

  Future<void> delete(String path);
}

/// [AppwriteStorageGateway] backed by the Appwrite `Storage` service.
///
/// Appwrite file ids cannot contain slashes, so [path] is folded into a
/// deterministic id that keeps the original name readable in download URLs.
final class SdkAppwriteStorageGateway implements AppwriteStorageGateway {
  SdkAppwriteStorageGateway({
    required this.client,
    required this.storage,
    required this.config,
  });

  final appwrite.Client client;
  final appwrite.Storage storage;
  final AppwriteConfig config;

  @override
  Future<StoredFile> upload({
    required String path,
    required List<int> bytes,
    String? contentType,
    ProgressCallback? onProgress,
  }) async {
    final file = await storage.createFile(
      bucketId: config.bucketId,
      fileId: _fileId(path),
      file: appwrite.InputFile.fromBytes(
        bytes: bytes,
        filename: _fileName(path),
        contentType: contentType,
      ),
      onProgress: (progress) {
        onProgress?.call((progress.progress / 100).clamp(0, 1).toDouble());
      },
    );
    return StoredFile(
      path: path,
      url: _viewUrl(path).toString(),
      size: file.sizeOriginal,
      contentType: file.mimeType,
    );
  }

  @override
  Future<List<int>> download(
    String path, {
    ProgressCallback? onProgress,
  }) async {
    final Uint8List bytes = await storage.getFileDownload(
      bucketId: config.bucketId,
      fileId: _fileId(path),
    );
    onProgress?.call(1);
    return bytes;
  }

  @override
  Future<Uri> url(String path) async => _viewUrl(path);

  @override
  Future<void> delete(String path) async {
    await storage.deleteFile(bucketId: config.bucketId, fileId: _fileId(path));
  }

  Uri _viewUrl(String path) {
    final trimmed = client.endPoint.endsWith('/')
        ? client.endPoint.substring(0, client.endPoint.length - 1)
        : client.endPoint;
    final route =
        '/storage/buckets/${Uri.encodeComponent(config.bucketId)}'
        '/files/${Uri.encodeComponent(_fileId(path))}/view';
    return Uri.parse(
      '$trimmed$route',
    ).replace(queryParameters: <String, String>{'project': config.projectId});
  }

  String _fileId(String path) {
    final slug = path
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
        .replaceFirst(RegExp(r'^[^A-Za-z0-9]+'), '');
    final base = slug.isEmpty ? 'file' : slug;
    final readable = base.length <= 27 ? base : base.substring(0, 27);
    final hash = _fnv1a(path).toUnsigned(32).toRadixString(16).padLeft(8, '0');
    return '$readable-$hash';
  }

  String _fileName(String path) {
    final segments = path.split(RegExp(r'[/\\]'));
    final name = segments.isEmpty ? '' : segments.last.trim();
    return name.isEmpty ? 'file' : name;
  }

  int _fnv1a(String value) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
