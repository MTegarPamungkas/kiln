import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/dio/dio_config.dart';

void main() {
  test('defaults contain a valid base URL and timeout', () {
    final uri = Uri.tryParse(DioConfig.defaults.baseUrl);

    expect(uri, isNotNull);
    expect(uri!.hasScheme, isTrue);
    expect(uri.host, isNotEmpty);
    expect(DioConfig.defaults.connectTimeout.inSeconds, greaterThan(0));
    expect(DioConfig.defaults.receiveTimeout.inSeconds, greaterThan(0));
  });
}
