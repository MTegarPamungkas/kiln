import 'package:kiln_testing/kiln_testing.dart';

import 'test_support.dart';

void main() {
  authRepositoryContract(
    description: 'AppwriteAuth',
    create: () => createFakeAuth().auth,
  );

  remoteDatabaseContract(
    description: 'AppwriteRemoteDatabase',
    create: () => createFakeRemoteDatabase().database,
  );

  fileStorageContract(
    description: 'AppwriteFileStorage',
    create: () => createFakeFileStorage(),
  );
}
