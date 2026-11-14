# Cloud functions

The extension's `functions` capability wraps the [CloudFunctions](../../../packages/kiln_core/lib/src/contracts/cloud_functions.dart)
contract: the application invokes functions deployed on the Appwrite project
and receives the execution result, without ever touching the Appwrite SDK
directly.

## Deploy a function

Functions are deployed from the Appwrite console or the CLI — the extension
only invokes them. A minimal Node runtime function (`src/main.js`):

```js
module.exports = async function (context) {
  const name = context.req.bodyJson?.name ?? 'world';
  return context.res.json({
    message: `Hello, ${name}!`,
  });
};
```

Package the directory as a tar.gz and deploy it with `activate: true` so the
`execute` permission includes the `users` role for signed-in callers.

## Invoke from the application

```dart
final functions = registry.read<CloudFunctions>();
final execution = await functions.invoke('hello-kiln', body: {'name': 'Kiln'});

// execution.status: completed | failed
// execution.statusCode: the function's HTTP-style response code
// execution.body / execution.bodyJson: the raw or parsed response
// execution.logs / execution.errors: backend-side capture
```

`invoke` throws a [Failure] only for transport, permission, validation, and
lookup problems. A function that itself fails still completes the invocation —
check `status`, `statusCode`, and `errors` on the returned execution.

## Failure mapping

| Condition | Failure code |
| --- | --- |
| Function id missing / unsupported HTTP method | `validation.invalid_input` |
| Function id does not exist (404) | `functions.not_found` |
| No session or insufficient execute permission (401/403) | `auth.unauthorized` / `permission.denied` |
| Rate limited (429) | `network.server`, retryable |
| Backend error (5xx) / transport error | `unavailable` / `network.*`, retryable |
