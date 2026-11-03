import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_config.dart';

void main() {
  test('defaults carry the rendered prompts', () {
    const config = BiometricConfig.defaults;

    expect(config.reason, '{{{reason}}}');
    expect(config.gracePeriod, const Duration(seconds: {{{grace_seconds}}}));
    expect(config.biometricOnly, {{{biometric_only}}});
  });
}
