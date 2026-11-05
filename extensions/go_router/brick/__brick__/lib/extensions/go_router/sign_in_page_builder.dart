import 'package:flutter/widgets.dart';

/// Optional replacement for the built-in sign-in page.
///
/// Register an implementation in the [Registry] before the go_router module
/// registers so the auth redirect renders the application's own sign-in form.
abstract interface class SignInPageBuilder {
  Widget build(BuildContext context);
}
