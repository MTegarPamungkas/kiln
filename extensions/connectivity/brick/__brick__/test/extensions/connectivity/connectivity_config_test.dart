import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/connectivity/connectivity_config.dart';

void main() {
  test('defaults carry the rendered probe and debounce settings', () {
    const config = ConnectivityConfig.defaults;

    expect(config.probeInterval, const Duration(seconds: 30));
    expect(config.probeTimeout, const Duration(seconds: 5));
    expect(config.debounceWindow, const Duration(milliseconds: 500));
  });
}
