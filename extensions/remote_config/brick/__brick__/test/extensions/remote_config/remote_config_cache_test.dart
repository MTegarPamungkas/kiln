import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_cache.dart';

void main() {
  test('round-trips a snapshot through storage', () async {
    final storage = InMemoryStorage();
    final cache = StorageRemoteConfigCache(storage: storage);
    final fetchedAt = DateTime.utc(2026, 11, 21, 1);

    await cache.save(
      RemoteConfigSnapshot(
        values: <String, Object?>{'limit': 3, 'on': true},
        fetchedAt: fetchedAt,
      ),
    );
    final loaded = await cache.load();

    expect(loaded, isNotNull);
    expect(loaded!.fetchedAt, fetchedAt);
    expect(loaded.values, <String, Object?>{'limit': 3, 'on': true});
  });

  test('drops a malformed snapshot instead of failing startup', () async {
    final storage = InMemoryStorage();
    final cache = StorageRemoteConfigCache(storage: storage);
    await storage.write('remote_config.snapshot', 'not json');

    expect(await cache.load(), isNull);
    expect(await storage.containsKey('remote_config.snapshot'), isFalse);
  });

  test('drops a snapshot without a timestamp or values', () async {
    final storage = InMemoryStorage(<String, String>{
      'remote_config.snapshot': '{"values":{"a":1}}',
    });
    final cache = StorageRemoteConfigCache(storage: storage);

    expect(await cache.load(), isNull);
    expect(await storage.containsKey('remote_config.snapshot'), isFalse);
  });

  test('clear removes the snapshot', () async {
    final storage = InMemoryStorage();
    final cache = StorageRemoteConfigCache(storage: storage);
    await cache.save(
      RemoteConfigSnapshot(
        values: const <String, Object?>{'a': 1},
        fetchedAt: DateTime.utc(2026, 11, 21),
      ),
    );

    await cache.clear();

    expect(await cache.load(), isNull);
  });
}
