import 'package:kiln_core/kiln_core.dart';

/// One error captured by [FakeCrashReporter].
final class CrashRecord {
  const CrashRecord(this.error, this.stackTrace, this.context);

  final Object error;
  final StackTrace? stackTrace;
  final Map<String, Object?> context;
}

/// One breadcrumb captured by [FakeCrashReporter].
final class BreadcrumbRecord {
  const BreadcrumbRecord(this.message, this.data);

  final String message;
  final Map<String, Object?> data;
}

/// [CrashReporter] that records everything in memory.
final class FakeCrashReporter implements CrashReporter {
  final List<CrashRecord> errors = <CrashRecord>[];
  final List<String> messages = <String>[];
  final List<BreadcrumbRecord> breadcrumbs = <BreadcrumbRecord>[];
  final Map<String, Map<String, Object?>> contexts =
      <String, Map<String, Object?>>{};
  String? userId;

  @override
  Future<void> captureError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) async {
    errors.add(CrashRecord(error, stackTrace, context));
  }

  @override
  Future<void> captureMessage(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  }) async {
    final rendered = context.isEmpty ? message : '$message $context';
    messages.add(rendered);
  }

  @override
  Future<void> addBreadcrumb(
    String message, {
    Map<String, Object?> data = const <String, Object?>{},
  }) async {
    breadcrumbs.add(BreadcrumbRecord(message, data));
  }

  @override
  Future<void> setUser(String? newUserId) async {
    userId = newUserId;
  }

  @override
  Future<void> setContext(String key, Map<String, Object?> value) async {
    contexts[key] = value;
  }
}
