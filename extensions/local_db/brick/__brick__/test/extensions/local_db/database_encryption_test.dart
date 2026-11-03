import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:{{app_name}}/extensions/local_db/database_encryption.dart';
import 'package:{{app_name}}/extensions/local_db/sembast_local_database.dart';

void main() {
  test('encrypts records with a key stored in SecureStorage', () async {
    final secureStorage = InMemorySecureStorage();
    final codec = await const DatabaseEncryption().codec(
      secureStorage: secureStorage,
      databaseName: 'encrypted.db',
    );

    expect(codec, isNotNull);
    expect(codec?.signature, 'aes-gcm');
    expect(await secureStorage.read('local_db.encrypted.db.key'), isNotNull);

    final database = SembastLocalDatabase(
      database: await databaseFactoryMemory.openDatabase(
        'encrypted_${DateTime.now().microsecondsSinceEpoch}.db',
        codec: codec,
      ),
    );
    await database.put('users', '1', {'name': 'Tegar'});
    expect(await database.get('users', '1'), {'name': 'Tegar'});
    await database.close();
  });

  test('returns no codec without SecureStorage', () async {
    expect(
      await const DatabaseEncryption().codec(
        secureStorage: null,
        databaseName: 'plain.db',
      ),
      isNull,
    );
  });
}
