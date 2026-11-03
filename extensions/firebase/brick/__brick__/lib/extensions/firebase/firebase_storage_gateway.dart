import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart' as storage;
import 'package:kiln_core/kiln_core.dart';

/// Cloud Storage access that can be faked without a Firebase app.
abstract interface class FirebaseStorageGateway {
  Future<StoredFile> upload(FileUpload file, {ProgressCallback? onProgress});

  Future<List<int>> download(String path, {ProgressCallback? onProgress});

  Future<Uri> url(String path);

  Future<void> delete(String path);

  Future<void> useEmulator(String host, int port);
}

/// [FirebaseStorageGateway] backed by Cloud Storage for Firebase.
final class SdkFirebaseStorageGateway implements FirebaseStorageGateway {
  SdkFirebaseStorageGateway({this.firebaseStorage});

  /// `Reference.getData` refuses payloads above this size, so make the limit
  /// explicit instead of relying on the plugin default.
  static const int maxDownloadBytes = 100 * 1024 * 1024;

  storage.FirebaseStorage? firebaseStorage;

  storage.FirebaseStorage get _instance =>
      firebaseStorage ??= storage.FirebaseStorage.instance;

  @override
  Future<StoredFile> upload(
    FileUpload file, {
    ProgressCallback? onProgress,
  }) async {
    final reference = _instance.ref(file.path);
    final metadata = storage.SettableMetadata(
      contentType: file.contentType,
      customMetadata: file.metadata.isEmpty ? null : file.metadata,
    );
    final task = reference.putData(Uint8List.fromList(file.bytes), metadata);

    var reported = 0.0;
    final subscription = task.snapshotEvents.listen((snapshot) {
      final total = snapshot.totalBytes;
      if (total <= 0) {
        return;
      }
      final progress = (snapshot.bytesTransferred / total)
          .clamp(0.0, 1.0)
          .toDouble();
      if (progress <= reported) {
        return;
      }
      reported = progress;
      onProgress?.call(progress);
    });
    try {
      await task;
    } finally {
      await subscription.cancel();
    }
    if (reported < 1) {
      onProgress?.call(1);
    }
    return StoredFile(
      path: file.path,
      url: await reference.getDownloadURL(),
      size: file.bytes.length,
      contentType: file.contentType,
    );
  }

  @override
  Future<List<int>> download(
    String path, {
    ProgressCallback? onProgress,
  }) async {
    final data = await _instance.ref(path).getData(maxDownloadBytes);
    if (data == null) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'object-not-found',
        message: 'Berkas $path tidak ditemukan.',
      );
    }
    onProgress?.call(1);
    return data.toList(growable: false);
  }

  @override
  Future<Uri> url(String path) async {
    return Uri.parse(await _instance.ref(path).getDownloadURL());
  }

  @override
  Future<void> delete(String path) => _instance.ref(path).delete();

  @override
  Future<void> useEmulator(String host, int port) =>
      _instance.useStorageEmulator(host, port);
}
