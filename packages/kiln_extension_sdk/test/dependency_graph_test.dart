import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('DependencyGraph', () {
    late DependencyGraph graph;

    setUp(() {
      graph = DependencyGraph([
        extensionFixture('dio'),
        extensionFixture('http_retry'),
      ]);
    });

    test('finds transitive dependents', () {
      expect(graph.dependentsOf('dio'), {'http_retry'});
      expect(graph.dependentsOf('http_retry'), isEmpty);
    });

    test('removal order puts dependents first', () {
      expect(graph.removalOrder('dio'), ['http_retry', 'dio']);
    });

    test('renders text and mermaid graphs', () {
      expect(graph.toText(), contains('http_retry -> dio'));

      final mermaid = graph.toMermaid();
      expect(mermaid, startsWith('flowchart TD'));
      expect(mermaid, contains('http_retry --> dio'));
    });

    test('shows a missing provider in the graph', () {
      final broken = DependencyGraph([
        makeExtension(id: 'feature', requires: const ['missing']),
      ]);

      expect(broken.toText(), contains('?missing'));
      expect(broken.toMermaid(), contains('missing_missing'));
    });
  });
}
