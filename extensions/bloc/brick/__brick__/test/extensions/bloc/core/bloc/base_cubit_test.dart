import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/core/bloc/base_cubit.dart';

final class _TestCubit extends BaseCubit<int> {
  _TestCubit() : super(0);
}

void main() {
  test('safeEmit is a no-op after close', () async {
    final cubit = _TestCubit();
    await cubit.close();

    cubit.safeEmit(1);

    expect(cubit.state, 0);
  });

  test('runGuarded returns Ok and Err', () async {
    final cubit = _TestCubit();

    expect((await cubit.runGuarded(() => 42)).valueOrNull, 42);
    final failure = await cubit.runGuarded<int>(
      () => throw const Failure(
        code: FailureCode.configurationInvalid,
        message: 'bad',
      ),
    );
    expect(failure.failureOrNull?.code, FailureCode.configurationInvalid);
    await cubit.close();
  });
}
