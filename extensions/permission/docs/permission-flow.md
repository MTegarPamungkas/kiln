# Permission flow

`gate.requestPermission(kind)` walks a fixed sequence so the app never has to
re-implement platform quirks. The application owns the rationale UI; the SDK only
reports status and drives the request.

1. `PermissionKindGuard` rejects kinds the extension was not configured with, so a
   typo or an unused permission fails fast instead of prompting the user.
2. The status is read from the in-memory cache, falling back to the platform.
3. If already granted, the call returns immediately.
4. If denied and a rationale applies, the app shows it **before** the system
   dialog (an app-owned screen, never the SDK's).
5. The request goes to the platform and the result is cached.
6. On permanent denial, the SDK reports a distinct state so the app can deep-link
   to system settings.
7. The cache is cleared when the app resumes, so a change made in settings is read
   again on the next check.

Treat "denied" and "permanently denied" differently: the first is a normal retry
after a rationale, the second needs a path to settings.
