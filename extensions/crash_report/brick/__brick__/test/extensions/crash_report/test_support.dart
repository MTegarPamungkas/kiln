import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/crash_report/crash_report_config.dart';
import 'package:{{app_name}}/extensions/crash_report/crash_report_gateway.dart';
import 'package:{{app_name}}/extensions/crash_report/sentry_crash_reporter.dart';

/// One error captured by [FakeCrashReportGateway].
final class RecordedCrashError {
  const RecordedCrashError(this.error, this.stackTrace, this.context);

  final Object error;
  final StackTrace? stackTrace;
  final Map<String, Object?> context;
}

/// One message captured by [FakeCrashReportGateway].
final class RecordedCrashMessage {
  const RecordedCrashMessage(this.message, this.context);

  final String message;
  final Map<String, Object?> context;
}

/// One breadcrumb captured by [FakeCrashReportGateway].
final class RecordedCrashBreadcrumb {
  const RecordedCrashBreadcrumb(this.message, this.data);

  final String message;
  final Map<String, Object?> data;
}

/// [CrashReportGateway] that records calls instead of touching Sentry.
final class FakeCrashReportGateway implements CrashReportGateway {
  final List<CrashReportConfig> inits = <CrashReportConfig>[];
  final List<String?> environments = <String?>[];
  final List<RecordedCrashError> errors = <RecordedCrashError>[];
  final List<RecordedCrashMessage> messages = <RecordedCrashMessage>[];
  final List<RecordedCrashBreadcrumb> breadcrumbs =
      <RecordedCrashBreadcrumb>[];
  final Map<String, Map<String, Object?>> contexts =
      <String, Map<String, Object?>>{};
  String? userId;
  int initCalls = 0;
  int flushCalls = 0;
  int closeCalls = 0;
  Object? failure;

  RecordedCrashError? get lastError => errors.isEmpty ? null : errors.last;

  RecordedCrashMessage? get lastMessage =>
      messages.isEmpty ? null : messages.last;

  RecordedCrashBreadcrumb? get lastBreadcrumb =>
      breadcrumbs.isEmpty ? null : breadcrumbs.last;

  @override
  Future<void> init(CrashReportConfig config, {String? environment}) async {
    initCalls++;
    _maybeFail();
    inits.add(config);
    environments.add(environment);
  }

  @override
  Future<void> captureError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) async {
    _maybeFail();
    errors.add(RecordedCrashError(error, stackTrace, context));
  }

  @override
  Future<void> captureMessage(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  }) async {
    _maybeFail();
    messages.add(RecordedCrashMessage(message, context));
  }

  @override
  Future<void> addBreadcrumb(
    String message, {
    Map<String, Object?> data = const <String, Object?>{},
  }) async {
    _maybeFail();
    breadcrumbs.add(RecordedCrashBreadcrumb(message, data));
  }

  @override
  Future<void> setUser(String? newUserId) async {
    _maybeFail();
    userId = newUserId;
  }

  @override
  Future<void> setContext(String key, Map<String, Object?> value) async {
    _maybeFail();
    contexts[key] = value;
  }

  @override
  Future<void> flush() async {
    _maybeFail();
    flushCalls++;
  }

  @override
  Future<void> close() async {
    _maybeFail();
    closeCalls++;
  }

  void _maybeFail() {
    final error = failure;
    if (error != null) {
      throw error;
    }
  }
}

/// [CrashReporterContractHarness] backed by [SentryCrashReporter] over a fake.
final class SentryCrashReporterHarness implements CrashReporterContractHarness {
  SentryCrashReporterHarness([FakeCrashReportGateway? gateway])
    : gateway = gateway ?? FakeCrashReportGateway() {
    reporter = SentryCrashReporter(gateway: this.gateway);
  }

  final FakeCrashReportGateway gateway;

  @override
  late final CrashReporter reporter;

  @override
  int get errorCount => gateway.errors.length;

  @override
  Object? get lastError => gateway.lastError?.error;

  @override
  int get messageCount => gateway.messages.length;

  @override
  String? get lastMessage => gateway.lastMessage?.message;

  @override
  int get breadcrumbCount => gateway.breadcrumbs.length;

  @override
  String? get lastBreadcrumb => gateway.lastBreadcrumb?.message;

  @override
  String? get userId => gateway.userId;

  @override
  Map<String, Object?>? contextFor(String key) => gateway.contexts[key];
}
