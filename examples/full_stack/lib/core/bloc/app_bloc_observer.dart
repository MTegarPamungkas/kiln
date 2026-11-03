import 'package:bloc/bloc.dart';
import 'package:kiln_core/kiln_core.dart';

/// Logs Bloc transitions and errors with PII redaction.
final class AppBlocObserver extends BlocObserver {
  const AppBlocObserver({
    required this.logger,
    this.redactor = const PiiRedactor(),
  });

  final AppLogger logger;
  final PiiRedactor redactor;

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    logger.debug(
      'bloc ${bloc.runtimeType}',
      data: <String, Object?>{
        'current': redactor.redact('${change.currentState}'),
        'next': redactor.redact('${change.nextState}'),
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
