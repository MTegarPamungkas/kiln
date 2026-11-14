import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:kiln_core/kiln_core.dart';

import 'appwrite_push_native_config.dart';
import 'appwrite_push_native_transport.dart';

/// Registers the Appwrite Push transport for the signed-in user.
///
/// Requires the `appwrite` extension: it subscribes on the same client and
/// session, so no device token is registered anywhere.
final class AppwritePushNativeModule extends KilnModule {
  AppwritePushNativeModule({
    this.config = AppwritePushNativeConfig.defaults,
    this.autoSubscribe = true,
  });

  /// Settings rendered from the install prompts.
  final AppwritePushNativeConfig config;

  /// Whether [AppwritePushNativeTransport.start] is called during bootstrap.
  /// Turn this off to start the transport from the application.
  final bool autoSubscribe;

  AppwritePushNativeTransport? _transport;

  @override
  String get id => 'appwrite_push_native';

  @override
  Set<String> get provides => const <String>{'push_transport'};

  @override
  Set<String> get requires => const <String>{'auth'};

  @override
  Set<String> get platforms => const <String>{'android', 'ios'};

  @override
  void register(Registry registry) {
    final transport = AppwritePushNativeTransport(
      client: registry.read<appwrite.Client>(),
      auth: registry.read<AuthRepository>(),
      pushEndpoint: config.pushEndpoint,
      notificationTitle: config.notificationTitle,
      background: config.background,
    );
    _transport = transport;
    registry
      ..registerSingleton<AppwritePushNativeTransport>(transport)
      ..registerSingleton<PushTransport>(transport);
  }

  @override
  Future<void> ready(Registry registry) async {
    if (!autoSubscribe) {
      return;
    }
    try {
      await _transport?.start();
    } on Object catch (error) {
      registry.readOrNull<SupportRegistry>()?.record(
        id,
        SupportInfo.unsupported(
          SupportState.unavailable,
          message: 'Appwrite Push unavailable: $error',
          details: <String, Object?>{'error': '$error'},
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {
    await _transport?.dispose();
    _transport = null;
  }
}
