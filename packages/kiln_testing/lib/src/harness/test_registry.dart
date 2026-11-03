import 'package:kiln_core/kiln_core.dart';

import '../fakes/fake_account_management.dart';
import '../fakes/fake_analytics.dart';
import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_connectivity.dart';
import '../fakes/fake_crash_reporter.dart';
import '../fakes/fake_deep_links.dart';
import '../fakes/fake_env.dart';
import '../fakes/fake_file_storage.dart';
import '../fakes/fake_http_client.dart';
import '../fakes/fake_local_database.dart';
import '../fakes/fake_media_picker.dart';
import '../fakes/fake_notifications.dart';
import '../fakes/fake_permissions.dart';
import '../fakes/fake_remote_database.dart';
import '../fakes/fake_social_auth.dart';
import '../fakes/in_memory_secure_storage.dart';
import '../fakes/in_memory_storage.dart';
import '../fakes/recording_logger.dart';

/// Builds a [Registry] containing a fake for every core contract.
///
/// Pass an override to replace one fake while keeping the rest.
Registry createTestRegistry({
  HttpClient? httpClient,
  Storage? storage,
  SecureStorage? secureStorage,
  AuthRepository? authRepository,
  AccountManagement? accountManagement,
  SocialAuth? socialAuth,
  LocalDatabase? localDatabase,
  RemoteDatabase? remoteDatabase,
  FileStorage? fileStorage,
  NetworkMonitor? networkMonitor,
  Permissions? permissions,
  Notifications? notifications,
  DeepLinks? deepLinks,
  MediaPicker? mediaPicker,
  Analytics? analytics,
  CrashReporter? crashReporter,
  AppLogger? logger,
  Env? env,
  Clock? clock,
  SessionController? sessionController,
  ConsentController? consentController,
  SlotRegistry? slotRegistry,
  LifecycleController? lifecycleController,
}) {
  final registry = GetItRegistry();

  registry.registerSingleton<HttpClient>(httpClient ?? FakeHttpClient());
  registry.registerSingleton<Storage>(storage ?? InMemoryStorage());
  registry.registerSingleton<SecureStorage>(
    secureStorage ?? InMemorySecureStorage(),
  );
  registry.registerSingleton<AuthRepository>(
    authRepository ?? FakeAuthRepository(),
  );
  registry.registerSingleton<AccountManagement>(
    accountManagement ?? FakeAccountManagement(),
  );
  registry.registerSingleton<SocialAuth>(socialAuth ?? FakeSocialAuth());
  registry.registerSingleton<LocalDatabase>(
    localDatabase ?? FakeLocalDatabase(),
  );
  registry.registerSingleton<RemoteDatabase>(
    remoteDatabase ?? FakeRemoteDatabase(),
  );
  registry.registerSingleton<FileStorage>(fileStorage ?? FakeFileStorage());
  registry.registerSingleton<NetworkMonitor>(
    networkMonitor ?? FakeConnectivity(),
  );
  registry.registerSingleton<Permissions>(permissions ?? FakePermissions());
  registry.registerSingleton<Notifications>(
    notifications ?? FakeNotifications(),
  );
  registry.registerSingleton<DeepLinks>(deepLinks ?? FakeDeepLinks());
  registry.registerSingleton<MediaPicker>(mediaPicker ?? FakeMediaPicker());
  registry.registerSingleton<Analytics>(analytics ?? FakeAnalytics());
  registry.registerSingleton<CrashReporter>(
    crashReporter ?? FakeCrashReporter(),
  );
  registry.registerSingleton<AppLogger>(logger ?? RecordingLogger());
  registry.registerSingleton<Env>(env ?? FakeEnv());
  registry.registerSingleton<Clock>(clock ?? const SystemClock());

  final slots = slotRegistry ?? SlotRegistry();
  final session = sessionController ?? SessionController();
  final consent = consentController ?? ConsentController();
  final lifecycle = lifecycleController ?? LifecycleController();

  registry.registerSingleton<SlotRegistry>(slots);
  registry.registerSingleton<SessionController>(session);
  registry.registerSingleton<ConsentController>(consent);
  registry.registerSingleton<LifecycleController>(lifecycle);
  registry.registerSingleton<Lifecycle>(lifecycle);

  return registry;
}
