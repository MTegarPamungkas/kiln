import 'package:kiln_core/kiln_core.dart';

/// Debounces noisy connectivity changes before publishing them.
final class StatusStabilizer {
  StatusStabilizer({Duration window = const Duration(milliseconds: 500)})
    : _debouncer = Debouncer(delay: window);

  final Debouncer _debouncer;

  void add(NetworkStatus status, void Function(NetworkStatus status) emit) {
    _debouncer.run(() => emit(status));
  }

  void dispose() => _debouncer.dispose();
}
