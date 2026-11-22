import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/deep_link/deep_link_config.dart';
import 'package:{{app_name}}/extensions/deep_link/link_allowlist.dart';

void main() {
  final allowlist = LinkAllowlist(
    config: const DeepLinkConfig(
      scheme: 'kiln',
      allowedHosts: <String>['kiln.dev'],
      pathPrefixes: <String>['/app/'],
    ),
  );

  test('accepts the configured scheme regardless of case', () {
    expect(allowlist.allows(Uri.parse('kiln://app/profile/42')), isTrue);
    expect(allowlist.allows(Uri.parse('KILN://app/profile/42')), isTrue);
  });

  test('rejects unknown schemes', () {
    expect(allowlist.allows(Uri.parse('otherapp://profile/42')), isFalse);
    expect(allowlist.allows(Uri.parse('mailto:hello@kiln.dev')), isFalse);
  });

  test('reserved web schemes cannot bypass HTTPS host checks', () {
    final webScheme = LinkAllowlist(config: const DeepLinkConfig(scheme: 'https'));
    expect(webScheme.allows(Uri.parse('https://evil.test/app')), isFalse);
    final insecure = LinkAllowlist(config: const DeepLinkConfig(scheme: 'http'));
    expect(insecure.allows(Uri.parse('http://evil.test/app')), isFalse);
  });

  test('rejects encoded traversal and nested encoded separators', () {
    expect(allowlist.allows(Uri.parse('kiln:///app/%2e%2e/admin')), isFalse);
    expect(allowlist.allows(Uri.parse('kiln://app/%252e%252e/admin')), isFalse);
    expect(allowlist.allows(Uri.parse('https://kiln.dev/app/%255cadmin')), isFalse);
  });

  test('custom schemes obey route prefixes and optional custom hosts', () {
    expect(allowlist.allows(Uri.parse('kiln://profile/42')), isFalse);
    expect(allowlist.allows(Uri.parse('kiln://application/42')), isFalse);
    expect(allowlist.allows(Uri.parse('kiln:///app/42')), isTrue);
    final restricted = LinkAllowlist(config: const DeepLinkConfig(
      scheme: 'kiln', customSchemeHosts: ['orders'], pathPrefixes: ['/orders'],
    ));
    expect(restricted.allows(Uri.parse('kiln://orders/42')), isTrue);
    expect(restricted.allows(Uri.parse('kiln://other/orders/42')), isFalse);
    expect(restricted.allows(Uri.parse('kiln://user@orders/42')), isFalse);
    expect(restricted.allows(Uri.parse('kiln://orders:1234/42')), isFalse);
    expect(restricted.allows(Uri.parse('kiln:orders/42')), isFalse);
  });

  test('accepts https links on allowed hosts and paths', () {
    expect(allowlist.allows(Uri.parse('https://KILN.dev/app/42')), isTrue);
  });

  test('rejects https links on unknown hosts', () {
    expect(allowlist.allows(Uri.parse('https://evil.example/app/42')), isFalse);
    expect(allowlist.allows(Uri.parse('https://kiln.dev.evil.example/app')), isFalse);
  });

  test('rejects insecure http links', () {
    expect(allowlist.allows(Uri.parse('http://kiln.dev/app/42')), isFalse);
  });

  test('matches path prefixes by whole segment', () {
    expect(allowlist.allows(Uri.parse('https://kiln.dev/application')), isFalse);
    expect(allowlist.allows(Uri.parse('https://kiln.dev/web/42')), isFalse);
    expect(allowlist.allows(Uri.parse('https://kiln.dev/app')), isTrue);
  });

  test('accepts every path when no prefix is configured', () {
    final open = LinkAllowlist(
      config: const DeepLinkConfig(
        scheme: 'kiln',
        allowedHosts: <String>['kiln.dev'],
      ),
    );

    expect(open.restrictsPaths, isFalse);
    expect(open.allows(Uri.parse('https://kiln.dev/anything/at/all')), isTrue);
  });

  test('rejects universal links when no host is configured', () {
    final customOnly = LinkAllowlist(
      config: const DeepLinkConfig(scheme: 'kiln'),
    );

    expect(customOnly.acceptsUniversalLinks, isFalse);
    expect(customOnly.allows(Uri.parse('https://kiln.dev/profile')), isFalse);
    expect(customOnly.allows(Uri.parse('kiln://profile')), isTrue);
  });
}
