import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/core/riverpod/kiln_providers.dart';

/// Mirrors [SessionController] into a Riverpod notifier.
final class SessionNotifier extends Notifier<SessionStatus> {
  @override
  SessionStatus build() {
    final controller = ref.watch(kilnProvider<SessionController>());
    final subscription = controller.changes.listen((status) => state = status);
    ref.onDispose(subscription.cancel);
    return controller.status;
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionStatus>(
  SessionNotifier.new,
);
