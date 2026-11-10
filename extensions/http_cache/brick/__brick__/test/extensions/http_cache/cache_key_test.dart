import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/http_cache/cache_key.dart';

HttpRequest _request(Uri uri, {Map<String, String> headers = const {}}) {
  return HttpRequest(method: HttpMethod.get, uri: uri, headers: headers);
}

void main() {
  const builder = CacheKeyBuilder();
  final uri = Uri.parse('https://api.kiln.dev/users?page=1');

  test('includes method, URL, query, and Vary headers', () {
    final key = builder.build(
      _request(uri, headers: const {'Accept': 'application/json'}),
    );

    expect(key, contains('get'));
    expect(key, contains('page=1'));
    expect(key, contains('"accept":"application/json"'));
  });

  test('different Vary values produce different keys', () {
    final json = builder.build(
      _request(uri, headers: const {'Accept': 'application/json'}),
    );
    final text = builder.build(
      _request(uri, headers: const {'Accept': 'text/plain'}),
    );

    expect(json, isNot(text));
  });

  test('different query values produce different keys', () {
    expect(
      builder.build(_request(Uri.parse('https://api.kiln.dev/users?page=1'))),
      isNot(
        builder.build(
          _request(Uri.parse('https://api.kiln.dev/users?page=2')),
        ),
      ),
    );
  });

  test('normalizes configured header names and distinguishes absent values', () {
    const custom = CacheKeyBuilder(varyHeaders: {'Accept-Language'});
    expect(custom.build(_request(uri, headers: {'Accept-Language': 'en'})),
        isNot(custom.build(_request(uri, headers: {'accept-language': 'fr'}))));
    expect(custom.build(_request(uri)),
        isNot(custom.build(_request(uri, headers: {'accept-language': ''}))));
  });

  test('header delimiters cannot collide with another variant', () {
    final first = builder.build(_request(uri, headers: {
      'accept': 'a|accept-encoding=b', 'accept-encoding': 'c',
    }));
    final second = builder.build(_request(uri, headers: {
      'accept': 'a', 'accept-encoding': 'b|accept-encoding=c',
    }));
    expect(first, isNot(second));
  });

  test('prefixFor returns the path', () {
    expect(builder.prefixFor(_request(uri)), '/users');
  });
}
