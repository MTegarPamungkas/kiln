import 'package:kiln_core/kiln_core.dart';

import 'storage_config.dart';
import 'storage_failure_mapper.dart';
import 'storage_gateway.dart';

/// [Storage] backed by a [StorageGateway].
final class SharedPreferencesStorage implements Storage {
  SharedPreferencesStorage({
    required this.gateway,
    this.config = StorageConfig.defaults,
  });

  final StorageGateway gateway;
  final StorageConfig config;

  String _key(String key) => '${config.prefix}$key';

  @override
  Future<String?> read(String key) async {
    try {
      return await gateway.read(_key(key));
    } catch (error, stackTrace) {
      throw mapStorageError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await gateway.write(_key(key), value);
    } catch (error, stackTrace) {
      throw mapStorageError(
        error,
        stackTrace: stackTrace,
        code: FailureCode.storageWriteFailed,
      );
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await gateway.delete(_key(key));
    } catch (error, stackTrace) {
      throw mapStorageError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      return await gateway.containsKey(_key(key));
    } catch (error, stackTrace) {
      throw mapStorageError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<Set<String>> keys() async {
    try {
      final all = await gateway.keys();
      return <String>{
        for (final key in all)
          if (key.startsWith(config.prefix))
            key.substring(config.prefix.length),
      };
    } catch (error, stackTrace) {
      throw mapStorageError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> clear() async {
    try {
      final all = await gateway.keys();
      for (final key in all) {
        if (key.startsWith(config.prefix)) {
          await gateway.delete(key);
        }
      }
    } catch (error, stackTrace) {
      throw mapStorageError(
        error,
        stackTrace: stackTrace,
        code: FailureCode.storageWriteFailed,
      );
    }
  }
}
