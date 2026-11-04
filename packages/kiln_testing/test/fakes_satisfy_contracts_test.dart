import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';

final class _AnalyticsHarness implements AnalyticsContractHarness {
  final FakeAnalytics fake = FakeAnalytics();

  @override
  Analytics get analytics => fake;

  @override
  int get eventCount => fake.events.length;

  @override
  String? get lastEventName =>
      fake.events.isEmpty ? null : fake.events.last.name;

  @override
  Map<String, Object?> get lastEventProperties =>
      fake.events.isEmpty ? const {} : fake.events.last.properties;

  @override
  int get identifyCount => fake.identities.length;

  @override
  String? get lastUserId =>
      fake.identities.isEmpty ? null : fake.identities.last.userId;

  @override
  Map<String, Object?> get lastTraits =>
      fake.identities.isEmpty ? const {} : fake.identities.last.traits;

  @override
  int get resetCount => fake.resetCalls;
}

final class _CrashReporterHarness implements CrashReporterContractHarness {
  final FakeCrashReporter fake = FakeCrashReporter();

  @override
  CrashReporter get reporter => fake;

  @override
  int get errorCount => fake.errors.length;

  @override
  Object? get lastError => fake.errors.isEmpty ? null : fake.errors.last.error;

  @override
  int get messageCount => fake.messages.length;

  @override
  String? get lastMessage => fake.messages.isEmpty ? null : fake.messages.last;

  @override
  int get breadcrumbCount => fake.breadcrumbs.length;

  @override
  String? get lastBreadcrumb =>
      fake.breadcrumbs.isEmpty ? null : fake.breadcrumbs.last.message;

  @override
  String? get userId => fake.userId;

  @override
  Map<String, Object?>? contextFor(String key) => fake.contexts[key];
}

final class _LoggerHarness implements LoggerContractHarness {
  final RecordingLogger fake = RecordingLogger();

  @override
  AppLogger get logger => fake;

  @override
  List<LogRecord> get records => fake.records;
}

void main() {
  httpClientContract(
    build: (responder) => FakeHttpClient(onRequest: responder),
    description: 'FakeHttpClient',
  );
  storageContract(
    create: () => InMemoryStorage(),
    description: 'InMemoryStorage',
  );
  secureStorageContract(
    create: () => InMemorySecureStorage(),
    description: 'InMemorySecureStorage',
  );
  authRepositoryContract(
    create: () => FakeAuthRepository(),
    description: 'FakeAuthRepository',
  );
  accountManagementContract(
    create: () => FakeAccountManagement(),
    description: 'FakeAccountManagement',
  );
  socialAuthContract(
    create: () => FakeSocialAuth(),
    description: 'FakeSocialAuth',
  );
  localDatabaseContract(
    create: () => FakeLocalDatabase(),
    description: 'FakeLocalDatabase',
  );
  remoteDatabaseContract(
    create: () => FakeRemoteDatabase(),
    description: 'FakeRemoteDatabase',
  );
  paginatedRemoteDatabaseContract(
    create: () => FakeRemoteDatabase(),
    description: 'FakeRemoteDatabase',
  );
  batchRemoteDatabaseContract(
    create: () => FakeRemoteDatabase(),
    description: 'FakeRemoteDatabase',
  );
  fileStorageContract(
    create: () => FakeFileStorage(),
    description: 'FakeFileStorage',
  );
  connectivityContract(
    create: () {
      final fake = FakeConnectivity();
      return (monitor: fake, emit: fake.setStatus);
    },
    description: 'FakeConnectivity',
  );
  permissionsContract(
    create: () {
      final fake = FakePermissions();
      return (permissions: fake, setStatus: fake.setStatus);
    },
    description: 'FakePermissions',
  );
  notificationsContract(
    create: () {
      final fake = FakeNotifications();
      return (notifications: fake, emitTap: fake.emitTap);
    },
    description: 'FakeNotifications',
  );
  deepLinksContract(
    create: () {
      final fake = FakeDeepLinks();
      return (deepLinks: fake, emit: fake.emit);
    },
    description: 'FakeDeepLinks',
  );
  mediaPickerContract(
    create: ({result, cancelled, failure}) => FakeMediaPicker(
      result: result,
      cancelled: cancelled ?? false,
      failure: failure,
    ),
    description: 'FakeMediaPicker',
  );
  analyticsContract(
    create: _AnalyticsHarness.new,
    description: 'FakeAnalytics',
  );
  crashReporterContract(
    create: _CrashReporterHarness.new,
    description: 'FakeCrashReporter',
  );
  loggerContract(create: _LoggerHarness.new, description: 'RecordingLogger');

  group('test registry', () {
    test('contains every contract by default', () {
      final registry = createTestRegistry();

      expect(registry.read<HttpClient>(), isA<HttpClient>());
      expect(registry.read<Storage>(), isA<Storage>());
      expect(registry.read<SecureStorage>(), isA<SecureStorage>());
      expect(registry.read<AuthRepository>(), isA<AuthRepository>());
      expect(registry.read<AccountManagement>(), isA<AccountManagement>());
      expect(registry.read<SocialAuth>(), isA<SocialAuth>());
      expect(registry.read<LocalDatabase>(), isA<LocalDatabase>());
      expect(registry.read<RemoteDatabase>(), isA<RemoteDatabase>());
      expect(registry.read<FileStorage>(), isA<FileStorage>());
      expect(registry.read<NetworkMonitor>(), isA<NetworkMonitor>());
      expect(registry.read<Permissions>(), isA<Permissions>());
      expect(registry.read<Notifications>(), isA<Notifications>());
      expect(registry.read<DeepLinks>(), isA<DeepLinks>());
      expect(registry.read<MediaPicker>(), isA<MediaPicker>());
      expect(registry.read<Analytics>(), isA<Analytics>());
      expect(registry.read<CrashReporter>(), isA<CrashReporter>());
      expect(registry.read<AppLogger>(), isA<AppLogger>());
      expect(registry.read<Env>(), isA<Env>());
      expect(registry.read<Clock>(), isA<Clock>());
      expect(registry.read<SessionController>(), isA<SessionController>());
      expect(registry.read<ConsentController>(), isA<ConsentController>());
      expect(registry.read<SlotRegistry>(), isA<SlotRegistry>());
      expect(registry.read<LifecycleController>(), isA<LifecycleController>());
      expect(registry.read<Lifecycle>(), isA<Lifecycle>());
      expect(registry.read<Gate>(), isA<Gate>());
    });

    test('accepts an override without replacing the rest', () {
      final storage = InMemoryStorage();
      final registry = createTestRegistry(storage: storage);

      expect(registry.read<Storage>(), same(storage));
      expect(registry.read<HttpClient>(), isA<FakeHttpClient>());
    });
  });

  group('matchers', () {
    test('match ok, err, and failure codes', () {
      expect(const Ok<int>(1), isOk<int>());
      expect(const Ok<int>(1), isOk<int>(equals(1)));
      expect(
        const Err<int>(
          Failure(code: FailureCode.networkTimeout, message: 'timeout'),
        ),
        isErr<int>(isFailure(FailureCode.networkTimeout)),
      );
      expect(
        const Err<int>(
          Failure(code: FailureCode.networkTimeout, message: 'timeout'),
        ),
        hasCode(FailureCode.networkTimeout),
      );
    });
  });
}
