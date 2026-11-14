import 'package:kiln_testing/kiln_testing.dart';

void main() {
  pushTransportContract(
    description: 'AppwritePushNativeTransport',
    create: () => FakePushTransport(),
  );
}
