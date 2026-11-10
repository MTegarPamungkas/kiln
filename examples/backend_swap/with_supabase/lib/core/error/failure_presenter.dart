import 'package:kiln_core/kiln_core.dart';

/// Friendly failure copy supplied by the `l10n` extension.
abstract interface class FailureMessages {
  String messageFor(Failure failure);
}

/// Converts a [Failure] into a message a user can understand.
class FailurePresenter {
  const FailurePresenter({this.messages});

  final FailureMessages? messages;

  factory FailurePresenter.fromRegistry(Registry registry) {
    return FailurePresenter(messages: registry.readOrNull<FailureMessages>());
  }

  String present(Failure failure) =>
      messages?.messageFor(failure) ?? failure.message;
}
