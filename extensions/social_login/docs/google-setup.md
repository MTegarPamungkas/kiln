# Google setup

1. Create an OAuth client in the Google Cloud Console.
2. Register the Android package name and SHA-1.
3. Create an iOS client id with the app's bundle id.
4. Fill in the prompt:

```bash
kiln config set google_server_client_id=123-abc.apps.googleusercontent.com
kiln config set google_ios_client_id=123-def.apps.googleusercontent.com
```

`google_server_client_id` is used on Android and the web; `google_ios_client_id`
is used on iOS and macOS. If both are empty, the Google button does not appear
and `signIn` throws `Failure(auth.provider_disabled)`.

Google Sign-In 7 uses `GoogleSignIn.instance.initialize()` once. The gateway
calls it on the first sign-in, so no manual initialization is needed.
