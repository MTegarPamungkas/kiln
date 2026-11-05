import 'package:kiln_cli/kiln_cli.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('ErrorPresenter', () {
    late CapturedLoggerForPresenter captured;
    late ErrorPresenter presenter;

    setUp(() {
      captured = CapturedLoggerForPresenter();
      presenter = ErrorPresenter(captured.logger);
    });

    test('maps project errors', () {
      final code = presenter.present(
        const KilnException('missing answer', code: 'prompt.required'),
      );

      expect(code, ExitCodes.project);
      expect(captured.err.join('\n'), contains('missing answer'));
    });

    test('maps resolution conflicts', () {
      final code = presenter.present(
        const ResolutionException(<ResolutionConflict>[
          ResolutionConflict(
            kind: ConflictKind.exclusiveCategory,
            message: 'Only one state management extension',
            suggestion: 'Remove one',
          ),
        ]),
      );

      expect(code, ExitCodes.conflict);
      expect(captured.err.join('\n'), contains('Only one'));
      expect(captured.out.join('\n'), contains('Remove one'));
    });

    test('maps network failures', () {
      final code = presenter.present(
        const Failure(
          code: FailureCode.networkTimeout,
          message: 'timed out',
          kind: FailureKind.network,
        ),
      );

      expect(code, ExitCodes.network);
    });

    test('maps unknown errors to internal', () {
      expect(presenter.present(StateError('boom')), ExitCodes.internal);
    });

    test('verification errors use the verification exit code', () {
      expect(
        presenter.present(
          const KilnException('failed', code: 'verification.pub_get'),
        ),
        ExitCodes.verification,
      );
    });
  });
}

final class CapturedLoggerForPresenter {
  final List<String> out = <String>[];
  final List<String> err = <String>[];

  late final KilnLogger logger = KilnLogger(out: out.add, err: err.add);
}
