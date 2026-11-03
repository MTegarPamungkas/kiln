# Changelog

## 0.2.0

- **Breaking:** the sample shell and `AuthRedirect` are now opt-in.
  `includeSampleShell` and `enableAuthRedirect` default to `false`, so the
  router only resolves the routes the application contributes. Set
  `AppRouterConfig(includeSampleShell: true)` for the starter tabs and
  `enableAuthRedirect: true` for a login wall.

## 0.1.1

- Add `SignInPageBuilder` so the application can replace the built-in
  sign-in page while keeping the auth redirect guard.
- Add `AppRouterConfig.includeSampleShell` and read an application supplied
  `AppRouterConfig` from the registry, so apps can replace the sample
  two-tab shell with their own routes.

## 0.1.0

- Initial router module, route slot, guards, auth redirect, session refresh,
  deep link and notification mappers, navigation observer, not found page,
  shell scaffold, and platform transitions.
