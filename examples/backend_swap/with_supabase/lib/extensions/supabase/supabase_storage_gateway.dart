// ignore_for_file: prefer_initializing_formals

import 'dart:typed_data';

import 'package:kiln_core/kiln_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';
import 'supabase_failure_mapper.dart';

/// Supabase Storage operations used by [SupabaseFileStorage].
///
/// The SDK does not report byte by byte progress, so the SDK implementation
/// calls [ProgressCallback] once with 1.0 after the transfer completes.
abstract interface class SupabaseStorageGateway {
  Future<void> upload(
    String path,
    List<int> bytes, {
    String? contentType,
    Map<String, String> metadata,
    bool upsert,
    ProgressCallback? onProgress,
  });

  Future<List<int>> download(String path, {ProgressCallback? onProgress});

  Future<Uri> createSignedUrl(String path, Duration expiresIn);

  Future<void> delete(String path);
}

/// [SupabaseStorageGateway] backed by `SupabaseStorageClient`.
final class SdkSupabaseStorageGateway implements SupabaseStorageGateway {
  SdkSupabaseStorageGateway({
    required SupabaseClientProvider provider,
    required this.bucket,
    this.upsertByDefault = false,
  }) : _provider = provider;

  final SupabaseClientProvider _provider;

  /// Bucket name where every file is stored.
  final String bucket;

  /// Overwrites a file with the same path when true.
  final bool upsertByDefault;

  @override
  Future<void> upload(
    String path,
    List<int> bytes, {
    String? contentType,
    Map<String, String> metadata = const <String, String>{},
    bool upsert = false,
    ProgressCallback? onProgress,
  }) async {
    try {
      await _client.uploadBinary(
        path,
        Uint8List.fromList(bytes),
        fileOptions: FileOptions(
          contentType: contentType,
          metadata: metadata.isEmpty
              ? null
              : Map<String, dynamic>.from(metadata),
          upsert: upsert || upsertByDefault,
        ),
      );
      onProgress?.call(1);
    } on Object catch (error, stackTrace) {
      throw _map(error, stackTrace, FailureCode.fileUploadFailed);
    }
  }

  @override
  Future<List<int>> download(
    String path, {
    ProgressCallback? onProgress,
  }) async {
    try {
      final data = await _client.download(path);
      onProgress?.call(1);
      return data;
    } on Object catch (error, stackTrace) {
      throw _map(error, stackTrace, FailureCode.fileDownloadFailed);
    }
  }

  @override
  Future<Uri> createSignedUrl(String path, Duration expiresIn) async {
    try {
      final url = await _client.createSignedUrl(path, expiresIn.inSeconds);
      final uri = Uri.parse(url);
      if (uri.hasScheme) {
        return uri;
      }
      return Uri.parse(_provider.config.url).resolve(url);
    } on Object catch (error, stackTrace) {
      throw _map(error, stackTrace, FailureCode.fileDownloadFailed);
    }
  }

  @override
  Future<void> delete(String path) async {
    try {
      await _client.remove(<String>[path]);
    } on Object catch (error, stackTrace) {
      throw _map(error, stackTrace, FailureCode.fileDeleteFailed);
    }
  }

  StorageFileApi get _client => _provider.client.storage.from(bucket);

  Failure _map(Object error, StackTrace stackTrace, FailureCode fallbackCode) {
    return mapSupabaseError(
      error,
      stackTrace: stackTrace,
      fallbackCode: fallbackCode,
      fallbackKind: FailureKind.storage,
    );
  }
}
