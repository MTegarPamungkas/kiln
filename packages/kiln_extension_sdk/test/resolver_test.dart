import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  group('ExtensionResolver', () {
    test('adds capability providers before the requested extension', () {
      final resolver = ExtensionResolver([
        extensionFixture('http_retry'),
        extensionFixture('dio'),
      ]);

      final plan = resolver.resolve(
        installed: const <String>{},
        requested: const {'http_retry'},
      );

      expect(plan.extensions.map((extension) => extension.id), [
        'dio',
        'http_retry',
      ]);
      expect(plan.added.map((extension) => extension.id), [
        'dio',
        'http_retry',
      ]);
      expect(
        plan.capabilities,
        containsAll(<String>['http_client', 'http_pipeline']),
      );
      expect(plan.activeContributions.single.contribution.priority, 20);
    });

    test('rejects two exclusive extensions in the same category', () {
      final resolver = ExtensionResolver([
        extensionFixture('bloc'),
        extensionFixture('riverpod'),
      ]);

      expect(
        () => resolver.resolve(
          installed: const <String>{},
          requested: const {'bloc', 'riverpod'},
        ),
        throwsA(
          isA<ResolutionException>().having(
            (error) => error.conflicts.map((conflict) => conflict.kind),
            'kinds',
            contains(ConflictKind.exclusiveCategory),
          ),
        ),
      );
    });

    test('reports a missing capability', () {
      final resolver = ExtensionResolver([
        makeExtension(id: 'feature', requires: const ['missing']),
      ]);

      expect(
        () => resolver.resolve(
          installed: const <String>{},
          requested: const {'feature'},
        ),
        throwsA(
          isA<ResolutionException>().having(
            (error) => error.conflicts.single.message,
            'message',
            contains('missing'),
          ),
        ),
      );
    });

    test('reports duplicate capability providers', () {
      final resolver = ExtensionResolver([
        makeExtension(id: 'one', provides: const ['http_client']),
        makeExtension(id: 'two', provides: const ['http_client']),
        makeExtension(id: 'feature', requires: const ['http_client']),
      ]);

      expect(
        () => resolver.resolve(
          installed: const <String>{},
          requested: const {'feature'},
        ),
        throwsA(
          isA<ResolutionException>().having(
            (error) => error.conflicts.single.kind,
            'kind',
            ConflictKind.duplicateCapability,
          ),
        ),
      );
    });

    test('reports a contribution to a slot nobody opens', () {
      final resolver = ExtensionResolver([
        makeExtension(
          id: 'orphan',
          contributions: const [
            Contribution(slot: 'custom.slot', item: 'Item'),
          ],
        ),
      ]);

      expect(
        () => resolver.resolve(
          installed: const <String>{},
          requested: const {'orphan'},
        ),
        throwsA(
          isA<ResolutionException>().having(
            (error) => error.conflicts.single.kind,
            'kind',
            ConflictKind.slotNotOpened,
          ),
        ),
      );
    });

    test('rejects a contribution with the wrong item type', () {
      final resolver = ExtensionResolver([
        makeExtension(
          id: 'opener',
          provides: const ['base'],
          slots: const [SlotDeclaration(name: 'custom.slot', item: 'Expected')],
        ),
        makeExtension(
          id: 'contributor',
          requires: const ['base'],
          contributions: const [
            Contribution(slot: 'custom.slot', item: 'Wrong'),
          ],
        ),
      ]);

      expect(
        () => resolver.resolve(
          installed: const <String>{},
          requested: const {'contributor'},
        ),
        throwsA(
          isA<ResolutionException>().having(
            (error) => error.conflicts.single.kind,
            'kind',
            ConflictKind.slotItemTypeMismatch,
          ),
        ),
      );
    });

    test('detects dependency cycles', () {
      final resolver = ExtensionResolver([
        makeExtension(id: 'a', provides: const ['a'], requires: const ['b']),
        makeExtension(id: 'b', provides: const ['b'], requires: const ['a']),
      ]);

      expect(
        () => resolver.resolve(
          installed: const <String>{},
          requested: const {'a'},
        ),
        throwsA(
          isA<ResolutionException>().having(
            (error) => error.conflicts.single.kind,
            'kind',
            ConflictKind.dependencyCycle,
          ),
        ),
      );
    });

    test('accepts host capabilities and host slots', () {
      final resolver = ExtensionResolver([
        makeExtension(
          id: 'feature',
          requires: const ['app_basic'],
          contributions: const [Contribution(slot: 'app.wrappers')],
        ),
      ]);

      final plan = resolver.resolve(
        installed: const <String>{},
        requested: const {'feature'},
        hostCapabilities: const {'app_basic'},
      );

      expect(plan.extensionIds, {'feature'});
      expect(plan.activeContributions, hasLength(1));
    });

    test('reports unknown extensions and already installed ones', () {
      final resolver = ExtensionResolver([extensionFixture('dio')]);

      expect(
        () => resolver.resolve(
          installed: const <String>{},
          requested: const {'missing'},
        ),
        throwsA(
          isA<ResolutionException>().having(
            (error) => error.conflicts.single.kind,
            'kind',
            ConflictKind.unknownExtension,
          ),
        ),
      );

      final plan = resolver.resolve(
        installed: const {'dio'},
        requested: const {'dio'},
      );
      expect(plan.added, isEmpty);
      expect(plan.warnings, contains('Extension "dio" is already installed'));
    });

    test('keeps installed extensions that were not requested', () {
      final resolver = ExtensionResolver([
        extensionFixture('dio'),
        extensionFixture('bloc'),
      ]);

      final plan = resolver.resolve(
        installed: const {'dio'},
        requested: const {'bloc'},
      );

      expect(plan.extensionIds, {'dio', 'bloc'});
    });
  });
}
