import 'dart:async';

import '../contracts/account_management.dart';
import '../contracts/analytics.dart';
import '../contracts/app_flavor.dart';
import '../contracts/auth.dart';
import '../contracts/calendar.dart';
import '../contracts/connectivity.dart';
import '../contracts/crash_reporter.dart';
import '../contracts/deep_links.dart';
import '../contracts/env.dart';
import '../contracts/file_storage.dart';
import '../contracts/http_client.dart';
import '../contracts/local_db.dart';
import '../contracts/location.dart';
import '../contracts/logger.dart';
import '../contracts/media_picker.dart';
import '../contracts/notifications.dart';
import '../contracts/permissions.dart';
import '../contracts/remote_config.dart';
import '../contracts/remote_database.dart';
import '../contracts/secure_storage.dart';
import '../contracts/share.dart';
import '../contracts/social_auth.dart';
import '../contracts/storage.dart';
import '../errors/failure.dart';
import '../errors/failure_codes.dart';
import '../errors/result.dart';
import '../privacy/consent.dart';
import '../runtime/lifecycle.dart';
import '../runtime/registry.dart';
import '../runtime/slot.dart';
import '../runtime/support.dart';
import '../session/session.dart';
import '../session/session_controller.dart';
import '../util/clock.dart';

/// A facade that turns contract calls into single `Result`-returning calls.
///
/// The application owns the UI; it reads a capability through a typed getter
/// (or [use]) and invokes it through [call] (or a convenience method) to
/// receive an [Ok]/[Err] value instead of catching thrown [Failure]s. The SDK
/// stays a pure gate: it only returns success or failure plus information.
final class Gate {
  const Gate(this.registry);

  final Registry registry;

  /// Reads a registered service by its contract type.
  T use<T extends Object>({String? instanceName}) {
    if (!has<T>(instanceName: instanceName)) {
      throw Failure(
        code: FailureCode.configurationMissing,
        message: 'The $T contract is not registered.',
        kind: FailureKind.configuration,
        details: <String, Object?>{
          'contract': '$T',
          'instance_name': ?instanceName,
        },
      );
    }
    return registry.read<T>(instanceName: instanceName);
  }

  /// Whether a contract is registered, so callers can probe optional
  /// capabilities before reading them.
  bool has<T extends Object>({String? instanceName}) =>
      registry.isRegistered<T>(instanceName: instanceName);

  /// Runs [action] and returns its value as [Ok], or the thrown [Failure]
  /// (or unexpected error) as [Err].
  ///
  /// Extra [info] is merged into the failure's `details` so the app receives
  /// context about the failed operation.
  Future<Result<T>> call<T>(
    FutureOr<T> Function() action, {
    FailureCode? code,
    String? message,
    Map<String, Object?> info = const <String, Object?>{},
  }) async {
    final result = await Result.guard<T>(action, code: code, message: message);
    return switch (result) {
      Ok<T>() => result,
      Err<T>(:final failure) when info.isNotEmpty => Err<T>(
        failure.copyWith(
          details: <String, Object?>{...failure.details, ...info},
        ),
      ),
      Err<T>() => result,
    };
  }

  // --- Typed service accessors ---

  AccountManagement get account => use();

  Analytics get analytics => use();

  AuthRepository get auth => use();

  CalendarService get calendar => use();

  NetworkMonitor get network => use();

  CrashReporter get crashReporter => use();

  DeepLinks get deepLinks => use();

  Env get env => use();

  FileStorage get files => use();

  HttpClient get http => use();

  HttpCache get cache => use();

  LocalDatabase get localDb => use();

  LocationProvider get location => use();

  AppLogger get logger => use();

  MediaPicker get mediaPicker => use();

  Notifications get notifications => use();

  Permissions get permissions => use();

  RemoteDatabase get remoteDb => use();

  RemoteConfig get remoteConfig => use();

  SecureStorage get secureStorage => use();

  ShareService get share => use();

  SocialAuth get socialAuth => use();

  Storage get storage => use();

  AppFlavor get flavor => use();

  SessionController get session => use();

  ConsentController get consent => use();

  Clock get clock => use();

  Lifecycle get lifecycle => use();

  SlotRegistry get slots => use();

  SupportRegistry get support => use();

  // --- One-call gate verbs ---

  // Permissions
  Future<Result<PermissionStatus>> permissionStatus(PermissionKind kind) =>
      call(() => permissions.status(kind));

  Future<Result<PermissionStatus>> requestPermission(
    PermissionKind kind, {
    bool requestIfDenied = true,
  }) => call(() => permissions.ensure(kind, requestIfDenied: requestIfDenied));

  // Auth
  Future<Result<AuthSession>> signIn({
    required String email,
    required String password,
  }) => call(() => auth.signIn(email: email, password: password));

  Future<Result<AuthSession>> signUp({
    required String email,
    required String password,
    String? displayName,
  }) => call(
    () =>
        auth.signUp(email: email, password: password, displayName: displayName),
  );

  Future<Result<void>> signOut() => call<void>(() => auth.signOut());

  // Remote database
  Future<Result<Map<String, Object?>>> remoteCreate(
    String collection,
    Map<String, Object?> data,
  ) => call(() => remoteDb.create(collection, data));

  Future<Result<Map<String, Object?>?>> remoteRead(
    String collection,
    String id,
  ) => call(() => remoteDb.read(collection, id));

  Future<Result<List<Map<String, Object?>>>> remoteQuery(
    String collection, {
    RemoteQuery? query,
  }) => call(() => remoteDb.query(collection, query: query));

  Future<Result<Map<String, Object?>>> remoteUpdate(
    String collection,
    String id,
    Map<String, Object?> data,
  ) => call(() => remoteDb.update(collection, id, data));

  Future<Result<void>> remoteDelete(String collection, String id) =>
      call<void>(() => remoteDb.delete(collection, id));

  // HTTP
  Future<Result<HttpResponse>> httpSend(HttpRequest request) =>
      call(() => http.send(request));

  Future<Result<HttpResponse>> httpGet(
    Uri uri, {
    Map<String, String> headers = const <String, String>{},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  }) => call(
    () => http.get(
      uri,
      headers: headers,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ),
  );

  Future<Result<HttpResponse>> httpPost(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const <String, String>{},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  }) => call(
    () => http.post(
      uri,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ),
  );

  Future<Result<HttpResponse>> httpPut(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const <String, String>{},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  }) => call(
    () => http.put(
      uri,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ),
  );

  Future<Result<HttpResponse>> httpPatch(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const <String, String>{},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  }) => call(
    () => http.patch(
      uri,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ),
  );

  Future<Result<HttpResponse>> httpDelete(
    Uri uri, {
    Object? body,
    Map<String, String> headers = const <String, String>{},
    Map<String, Object?>? queryParameters,
    HttpCancelToken? cancelToken,
  }) => call(
    () => http.delete(
      uri,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ),
  );

  // HTTP cache
  Future<Result<void>> invalidateCache(String prefix, {String? tag}) =>
      call<void>(() => cache.invalidate(prefix, tag: tag));

  Future<Result<void>> clearCache() => call<void>(() => cache.clear());

  // File storage
  Future<Result<StoredFile>> uploadFile(
    FileUpload file, {
    ProgressCallback? onProgress,
  }) => call(() => files.upload(file, onProgress: onProgress));

  Future<Result<List<int>>> downloadFile(
    String path, {
    ProgressCallback? onProgress,
  }) => call(() => files.download(path, onProgress: onProgress));

  // Local database
  Future<Result<Map<String, Object?>?>> localGet(
    String collection,
    String key,
  ) => call(() => localDb.get(collection, key));

  Future<Result<void>> localPut(
    String collection,
    String key,
    Map<String, Object?> data,
  ) => call<void>(() => localDb.put(collection, key, data));

  // Analytics
  Future<Result<void>> captureEvent(
    String event, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) => call<void>(() => analytics.capture(event, properties: properties));

  Future<Result<void>> identifyUser(
    String userId, {
    Map<String, Object?> traits = const <String, Object?>{},
  }) => call<void>(() => analytics.identify(userId, traits: traits));

  Future<Result<void>> resetAnalytics() => call<void>(() => analytics.reset());

  // Remote config
  Future<Result<void>> fetchRemoteConfig() =>
      call<void>(() => remoteConfig.fetchAndActivate());

  // Account management
  Future<Result<void>> sendPasswordReset(String email) =>
      call<void>(() => account.sendPasswordResetEmail(email));

  Future<Result<void>> sendEmailVerification() =>
      call<void>(() => account.sendEmailVerification());

  Future<Result<void>> reloadUser() => call<void>(() => account.reloadUser());

  Future<Result<void>> updateDisplayName(String displayName) =>
      call<void>(() => account.updateDisplayName(displayName));

  // Calendar & crash reporting
  Future<Result<bool>> addCalendarEvent(CalendarEvent event) =>
      call(() => calendar.addEvent(event));

  Future<Result<void>> reportError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) => call<void>(
    () => crashReporter.captureError(
      error,
      stackTrace: stackTrace,
      context: context,
    ),
  );

  Future<Result<void>> reportMessage(
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
  }) =>
      call<void>(() => crashReporter.captureMessage(message, context: context));

  // Media picker
  Future<Result<PickedImage?>> pickImage({
    MediaSource source = MediaSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) => call(
    () => mediaPicker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    ),
  );

  // Notifications
  Future<Result<bool>> requestNotificationPermission() =>
      call(() => notifications.requestPermission());

  Future<Result<void>> showNotification(NotificationMessage message) =>
      call<void>(() => notifications.show(message));

  Future<Result<void>> scheduleNotification(
    NotificationMessage message,
    DateTime when,
  ) => call<void>(() => notifications.schedule(message, when));

  Future<Result<void>> cancelNotification(int id) =>
      call<void>(() => notifications.cancel(id));

  Future<Result<void>> cancelAllNotifications() =>
      call<void>(() => notifications.cancelAll());

  // Secure storage
  Future<Result<String?>> readSecure(String key) =>
      call(() => secureStorage.read(key));

  Future<Result<void>> writeSecure(String key, String value) =>
      call<void>(() => secureStorage.write(key, value));

  Future<Result<void>> deleteSecure(String key) =>
      call<void>(() => secureStorage.delete(key));

  Future<Result<Map<String, String>>> readAllSecure() =>
      call(() => secureStorage.readAll());

  Future<Result<void>> clearSecure() => call<void>(() => secureStorage.clear());

  // Share & social auth
  Future<Result<ShareOutcome>> shareContent(
    ShareContent content, {
    ShareOrigin? origin,
  }) => call(() => share.share(content, origin: origin));

  Future<Result<SocialCredential?>> socialSignIn(SocialProvider provider) =>
      call(() => socialAuth.signIn(provider));

  Future<Result<void>> socialSignOut() => call<void>(() => socialAuth.signOut());

  // Storage
  Future<Result<String?>> readValue(String key) =>
      call(() => storage.read(key));

  Future<Result<void>> writeValue(String key, String value) =>
      call<void>(() => storage.write(key, value));

  Future<Result<void>> deleteValue(String key) =>
      call<void>(() => storage.delete(key));

  Future<Result<bool>> hasValue(String key) =>
      call(() => storage.containsKey(key));

  Future<Result<Set<String>>> storageKeys() => call(() => storage.keys());

  Future<Result<void>> clearValues() => call<void>(() => storage.clear());

  // Location
  Future<Result<GeoPosition>> currentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) => call(() => location.current(accuracy: accuracy));

  /// Whether the platform location service is currently enabled.
  Future<Result<bool>> locationServiceEnabled() =>
      call(() => location.isServiceEnabled());
}
