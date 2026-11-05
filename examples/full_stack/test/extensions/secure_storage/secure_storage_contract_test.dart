import 'package:kiln_testing/kiln_testing.dart';

import 'test_support.dart';

void main() {
  secureStorageContract(
    create: createTestSecureStorage,
    description: 'KeystoreSecureStorage',
  );
}
