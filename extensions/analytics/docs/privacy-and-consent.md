# Privacy and consent

## When events are sent

This extension is opt-in. `ConsentGateAnalytics` is the outermost layer and
checks `ConsentController.isGranted(ConsentCategory.analytics)` on every
`capture` and `identify` call. While permission has not been granted:

- there are no calls to the PostHog SDK;
- there is no wasted property scrubbing;
- no events or identities are sent.

Because the check happens per call, granting permission after the application is
running immediately enables sending without rebuilding the module. The first
grant initializes PostHog, re-enables it after an earlier revocation, and
identifies the session that is already signed in. A `beforeSend` filter drops
Dart-captured events if the SDK ever sees one while consent is missing.

Withdrawing permission calls the SDK's opt-out and clears its identity, so
queued events stop and later capture or identify calls never reach the transport.
The registered `Analytics` is the only public seam; the raw gateway and the
concrete PostHog reporter are private to the module.

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
```

The module reacts to the change: it opts the SDK out, resets the stored
identity, and updates support to "waiting for consent". Subsequent analytics
calls send nothing. Calling `Analytics.reset()` as well is harmless but no
longer required.
