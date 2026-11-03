# Changelog

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
