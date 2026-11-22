import 'package:kiln_testing/kiln_testing.dart';

void main() {
  cloudFunctionsContract(
    description: 'FakeCloudFunctions',
    create: FakeCloudFunctions.new,
  );
  pushTargetsContract(
    description: 'FakePushTargets',
    create: FakePushTargets.new,
  );
  pushTransportContract(
    description: 'FakePushTransport',
    create: FakePushTransport.new,
  );
}
