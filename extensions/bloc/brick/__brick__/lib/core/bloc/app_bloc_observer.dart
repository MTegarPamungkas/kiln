import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:kiln_core/kiln_core.dart';

/// Logs Bloc transitions and errors with PII redaction.
final class AppBlocObserver extends BlocObserver {
  const AppBlocObserver({
    required this.logger,
    this.redactor = const PiiRedactor(),
    this.logTransitions = kDebugMode,
  });

  final AppLogger logger;
  final PiiRedactor redactor;

  /// Whether state transitions are logged via [AppLogger.debug].
  ///
  /// Defaults to [kDebugMode] so release and profile builds do not pay for
  /// state stringification and PII redaction on every `emit()`.
  final bool logTransitions;

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (!logTransitions) {
      return;
    }
    logger.debug(
      'bloc ${bloc.runtimeType}',
      data: <String, Object?>{
        'current': redactor.redactText('${change.currentState}'),
        'next': redactor.redactText('${change.nextState}'),
      },
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    logger.error(
      'bloc error in ${bloc.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}
