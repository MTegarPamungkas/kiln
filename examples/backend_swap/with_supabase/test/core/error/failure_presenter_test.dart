import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:with_supabase/core/error/failure_presenter.dart';

final class _Messages implements FailureMessages {
  const _Messages();

  @override
  String messageFor(Failure failure) => 'localized:${failure.code.value}';
}

void main() {
  test('uses localized messages from the registry', () {
    final registry = createTestRegistry();
    registry.registerSingleton<FailureMessages>(const _Messages());
    final presenter = FailurePresenter.fromRegistry(registry);

    expect(
      presenter.present(
        const Failure(code: FailureCode.networkTimeout, message: 'timeout'),
      ),
      'localized:network.timeout',
    );
  });

  test('falls back to the failure message without localizations', () {
    const presenter = FailurePresenter();
    const failure = Failure(
      code: FailureCode.networkTimeout,
      message: 'timeout',
    );

    expect(presenter.present(failure), 'timeout');
  });

  test('does not throw when FailureMessages is not registered', () {
    final registry = createTestRegistry();
    final presenter = FailurePresenter.fromRegistry(registry);
    const failure = Failure(
      code: FailureCode.authUnauthorized,
      message: 'No subscription',
    );

    expect(presenter.present(failure), 'No subscription');
  });
}
