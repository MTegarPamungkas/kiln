# Permission flow

1. `PermissionKindGuard` rejects kinds that are not enabled.
2. Status is read from the cache or the platform.
3. If already granted, done.
4. If denied, the rationale is shown (optional).
5. The request is sent to the platform.
6. If permanently denied, the app is directed to settings.
7. The cache is cleared when the app resumes so the status from settings is
   read again.
