import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

final class _TestModule extends KilnModule {
  _TestModule(
    this.id, {
    this.provides = const <String>{},
    this.requires = const <String>{},
    this.optionalRequires = const <String>{},
  });

  @override
  final String id;
  @override
  final Set<String> provides;
  @override
  final Set<String> requires;
  @override
  final Set<String> optionalRequires;

  @override
  void register(Registry registry) {}
}

void main() {
  group('ModuleGraph', () {
    test(
      'orders providers before their consumers regardless of input order',
      () {
        final consumer = _TestModule('consumer', requires: const {'db'});
        final provider = _TestModule('provider', provides: const {'db'});
        final graph = ModuleGraph([consumer, provider]);

        final ordered = graph.resolve();

        expect(ordered.map((module) => module.id), ['provider', 'consumer']);
      },
    );

    test('orders optional providers first when they are installed', () {
      final consumer = _TestModule('consumer', optionalRequires: const {'db'});
      final provider = _TestModule('provider', provides: const {'db'});
      final graph = ModuleGraph([consumer, provider]);

      expect(graph.resolve().map((module) => module.id), [
        'provider',
        'consumer',
      ]);
    });

    test('ignores an optional requirement with no provider', () {
      final graph = ModuleGraph([
        _TestModule('consumer', optionalRequires: const {'missing'}),
      ]);

      expect(graph.resolve().single.id, 'consumer');
    });

    test('keeps input order for independent modules', () {
      final graph = ModuleGraph([
        _TestModule('a'),
        _TestModule('b'),
        _TestModule('c'),
      ]);

      expect(graph.resolve().map((module) => module.id), ['a', 'b', 'c']);
    });

    test('accepts capabilities provided by the host application', () {
      final graph = ModuleGraph([
        _TestModule('feature', requires: const {'app_basic'}),
      ]);

      final ordered = graph.resolve(availableCapabilities: const {'app_basic'});

      expect(ordered.single.id, 'feature');
    });

    test('throws when a required capability is missing', () {
      final graph = ModuleGraph([
        _TestModule('consumer', requires: const {'missing'}),
      ]);

      expect(
        graph.resolve,
        throwsA(
          isA<ModuleGraphException>()
              .having((error) => error.moduleId, 'moduleId', 'consumer')
              .having((error) => error.capability, 'capability', 'missing'),
        ),
      );
    });

    test('throws when a capability has two providers', () {
      final graph = ModuleGraph([
        _TestModule('one', provides: const {'db'}),
        _TestModule('two', provides: const {'db'}),
      ]);

      expect(
        graph.resolve,
        throwsA(
          isA<ModuleGraphException>().having(
            (error) => error.capability,
            'capability',
            'db',
          ),
        ),
      );
    });

    test('throws when two modules share an id', () {
      final graph = ModuleGraph([_TestModule('same'), _TestModule('same')]);

      expect(
        graph.resolve,
        throwsA(
          isA<ModuleGraphException>().having(
            (error) => error.moduleId,
            'moduleId',
            'same',
          ),
        ),
      );
    });

    test('detects a dependency cycle and reports it', () {
      final a = _TestModule('a', provides: const {'a'}, requires: const {'b'});
      final b = _TestModule('b', provides: const {'b'}, requires: const {'a'});

      expect(
        ModuleGraph([a, b]).resolve,
        throwsA(
          isA<ModuleGraphException>().having(
            (error) => error.cycle,
            'cycle',
            containsAll(<String>['a', 'b']),
          ),
        ),
      );
    });

    test('detects a module that requires its own capability', () {
      final module = _TestModule(
        'self',
        provides: const {'self'},
        requires: const {'self'},
      );

      expect(
        ModuleGraph([module]).resolve,
        throwsA(
          isA<ModuleGraphException>().having(
            (error) => error.cycle,
            'cycle',
            isNotEmpty,
          ),
        ),
      );
    });

    test('tolerates mutually optional dependencies', () {
      final logger = _TestModule(
        'logger',
        provides: const {'logger'},
        optionalRequires: const {'crash_reporter'},
      );
      final crash = _TestModule(
        'crash_report',
        provides: const {'crash_reporter'},
        optionalRequires: const {'logger'},
      );

      final ordered = ModuleGraph([crash, logger]).resolve();

      expect(
        ordered.map((module) => module.id),
        containsAll(<String>['logger', 'crash_report']),
      );
    });
  });
}
