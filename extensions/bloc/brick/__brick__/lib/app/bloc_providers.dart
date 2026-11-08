import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/app/app_wrappers.dart';
import 'package:{{app_name}}/core/bloc/session_bloc.dart';

/// Wraps the application with the global Bloc providers.
///
/// Feature blocs belong to the screen that needs them; only the session bridge
/// is global.
AppWrapper buildBlocAppWrapper(Registry registry) {
  return (context, child) => MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<SessionBloc>(
        create: (_) => SessionBloc(registry.read<SessionController>()),
      ),
    ],
    child: child,
  );
}
