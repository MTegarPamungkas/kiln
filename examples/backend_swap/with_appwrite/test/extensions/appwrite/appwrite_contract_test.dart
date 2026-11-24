import 'package:flutter_test/flutter_test.dart';
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

  test(
    'AppwriteFunctions contract runs against a real adapter harness',
    () {},
    skip: 'Requires an injected Appwrite Functions driver or a live project.',
  );

  test(
    'AppwritePushTargets contract runs against a real adapter harness',
    () {},
    skip: 'Requires an injected Appwrite push-target driver or a live project.',
  );

  fileStorageContract(
    description: 'AppwriteFileStorage',
    create: () => createFakeFileStorage(),
  );
}
