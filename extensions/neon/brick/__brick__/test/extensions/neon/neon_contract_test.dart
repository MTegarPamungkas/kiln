import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/neon/neon_file_storage.dart';
import 'package:{{app_name}}/extensions/neon/neon_remote_database.dart';

import 'test_support.dart';

void main() {
  remoteDatabaseContract(
    description: 'NeonRemoteDatabase',
    create: () => NeonRemoteDatabase(
      gateway: FakePostgrestGateway(),
      config: testConfig(),
    ),
  );

  fileStorageContract(
    description: 'NeonFileStorage',
    create: () => NeonFileStorage(gateway: FakeNeonStorageGateway()),
  );
}
