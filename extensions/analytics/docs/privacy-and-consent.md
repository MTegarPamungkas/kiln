# Privacy and consent

## When events are sent

This extension is opt-in. `ConsentGateAnalytics` is the outermost layer and
checks `ConsentController.isGranted(ConsentCategory.analytics)` on every
`capture` and `identify` call. While permission has not been granted:

- there are no calls to the PostHog SDK;
- there is no wasted property scrubbing;
- no events or identities are sent.

Because the check happens per call, granting permission after the application is
running immediately enables sending without rebuilding the module. Withdrawing
permission likewise stops the next events right away.

`reset` is always forwarded to the SDK because it only removes the identity
stored on the device and does not send an event.

## What is masked

`PiiScrubbingAnalytics` uses `PiiRedactor` before data reaches the gateway:

- event properties and identity traits are checked per key; sensitive keys such
  as `password`, `token`, `authorization`, `email`, and `phone` are replaced
  with `[redacted]`;
- text inside values is also cleaned of emails, Bearer tokens, and JWTs;
- maps and lists are processed recursively;
- `userId` is left unchanged because it serves as the pseudonymous identity used
  to tie events together.

Masking is the last line of defense, not permission to collect PII. Do not send
personal data the product does not need.

## Withdrawing consent

```dart
final consent = registry.read<ConsentController>();
consent.deny(ConsentCategory.analytics);
await registry.read<Analytics>().reset();
```

After permission is withdrawn, subsequent analytics calls send nothing. Call
`reset` if the application also wants to clear the identity already stored in
the SDK.
