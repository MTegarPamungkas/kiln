import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/neon/neon_auth_repository.dart';
import 'package:{{app_name}}/extensions/neon/neon_file_storage.dart';
import 'package:{{app_name}}/extensions/neon/neon_remote_database.dart';

import 'test_support.dart';

void main() {
  authRepositoryContract(
    description: 'NeonAuthRepository',
    create: () => NeonAuthRepository(
      gateway: FakeNeonAuthGateway(),
      controller: SessionController(),
    ),
  );

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
