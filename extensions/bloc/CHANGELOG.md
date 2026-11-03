# Changelog

## 0.2.0

- Removed the counter demo cubit and page. The extension keeps the Bloc observer, session cubit, and provider wiring.

## 0.1.3

- Add `BlocSupport` with observer and app-wrapper details.
- Create the slot registry when a module is used without bootstrap.

## 0.1.2

- Bootstrap test supplies a test `CoreCopy`, matching the app template now that
  the shell requires `l10n`.

## 0.1.1

- The app wrapper now provides `CounterCubit`, so the generated counter example
  can read it from the widget tree.

## 0.1.0

- Initial Bloc/Cubit foundation, session cubit, async cubit, observer, and
  counter example.
