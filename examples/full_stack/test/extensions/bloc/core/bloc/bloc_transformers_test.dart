import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/core/bloc/bloc_transformers.dart';

final class _IntBloc extends Bloc<int, int> {
  _IntBloc()
      : super(0) {
    on<int>(
      (event, emit) => emit(event),
      transformer: debounceEvents<int>(const Duration(milliseconds: 10)),
    );
  }
}

void main() {
  test('debounce emits only the last event in the window', () async {
    final bloc = _IntBloc();

    bloc
      ..add(1)
      ..add(2);
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(bloc.state, 2);
    await bloc.close();
  });
}
