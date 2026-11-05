import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

/// Observable state a test needs from a [CrashReporter] implementation.
abstract interface class CrashReporterContractHarness {
  CrashReporter get reporter;

  int get errorCount;

  Object? get lastError;

  int get messageCount;

  String? get lastMessage;

  int get breadcrumbCount;

  String? get lastBreadcrumb;

  String? get userId;

  Map<String, Object?>? contextFor(String key);
}

/// Behavior every [CrashReporter] implementation must share.
void crashReporterContract({
  required CrashReporterContractHarness Function() create,
  String description = 'CrashReporter',
}) {
  group('$description contract', () {
    test('captureError records the error and context', () async {
      final harness = create();
      final error = StateError('broken');

      await harness.reporter.captureError(
        error,
        context: const {'screen': 'home'},
      );

      expect(harness.errorCount, 1);
      expect(harness.lastError, same(error));
    });

    test('captureMessage records a message', () async {
      final harness = create();

      await harness.reporter.captureMessage('Something looks wrong');

      expect(harness.messageCount, 1);
      expect(harness.lastMessage, contains('Something looks wrong'));
    });

    test('addBreadcrumb records a breadcrumb', () async {
      final harness = create();

      await harness.reporter.addBreadcrumb('Opened profile');

      expect(harness.breadcrumbCount, 1);
      expect(harness.lastBreadcrumb, 'Opened profile');
    });

    test('setUser updates the reported user', () async {
      final harness = create();

      await harness.reporter.setUser('user-1');
      expect(harness.userId, 'user-1');

      await harness.reporter.setUser(null);
      expect(harness.userId, isNull);
    });

    test('setContext stores keyed context', () async {
      final harness = create();

      await harness.reporter.setContext('app', const {'flavor': 'staging'});

      expect(harness.contextFor('app')?['flavor'], 'staging');
    });
  });
}
