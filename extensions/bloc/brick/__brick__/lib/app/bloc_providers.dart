import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/app/app_wrappers.dart';
import 'package:{{app_name}}/core/bloc/session_cubit.dart';

/// Wraps the application with the global Bloc providers.
AppWrapper buildBlocAppWrapper(Registry registry) {
  return (context, child) => MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<SessionCubit>(
        create: (_) => SessionCubit(registry.read<SessionController>()),
      ),
    ],
    child: child,
  );
}
