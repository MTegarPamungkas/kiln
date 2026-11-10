import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/extensions/go_router/deep_link_route_mapper.dart';

void main() {
  const mapper = DeepLinkRouteMapper();

  test('maps universal links to their path', () {
    expect(
      mapper.map(Uri.parse('https://example.com/orders/42?tab=items#detail')),
      '/orders/42?tab=items#detail',
    );
    expect(mapper.map(Uri.parse('https://example.com/')), '/');
  });

  test('maps custom schemes using the host as the first segment', () {
    expect(mapper.map(Uri.parse('myapp://orders/42')), '/orders/42');
    expect(mapper.map(Uri.parse('myapp:///orders/42')), '/orders/42');
    expect(
      mapper.map(Uri.parse('myapp://explore?ref=email')),
      '/explore?ref=email',
    );
  });

  test('ignores unsupported and empty links', () {
    expect(mapper.map(Uri.parse('mailto:halo@example.com')), isNull);
    expect(mapper.map(Uri.parse('tel:+628123456789')), isNull);
    expect(mapper.map(Uri.parse('https://example.com')), isNull);
    expect(mapper.map(Uri.parse('myapp://')), isNull);
  });
}
