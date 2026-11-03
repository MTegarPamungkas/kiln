import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/social_login/nonce_generator.dart';

void main() {
  test('generates different url-safe nonces', () {
    final generator = NonceGenerator();

    final first = generator.generate();
    final second = generator.generate();

    expect(first, isNotEmpty);
    expect(first, isNot(second));
    expect(first, isNot(contains('=')));
    expect(first, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
  });

  test('hashes a nonce with SHA-256', () {
    final generator = NonceGenerator();

    expect(
      generator.sha256('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });
}
