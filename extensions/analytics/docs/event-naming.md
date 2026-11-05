# Event and property names

## Event names

Use the `object verb` pattern in lowercase English, for example
`project created`, `invite sent`, or `report exported`. Event names are a public
API: dashboards and funnels depend on them, so do not rename events that have
already been sent. Add a new event when the meaning changes.

- One event represents one thing that already happened.
- Do not include user ids, emails, or random values in event names.
- Do not create an event for every internal state change; pick moments that are
  meaningful for the product.

## Properties

Use `snake_case` for property keys, for example `plan`, `seat_count`, and
`created_at`. Values must be JSON-like:

- `String`, `bool`, and finite numbers are sent as is.
- `DateTime` becomes an ISO-8601 string.
- `Duration` becomes a number of milliseconds.
- `Enum` becomes its `name`.
- `Iterable` and `Map` are translated recursively; map keys must be `String`.
- `null` is dropped. Other values, including arbitrary objects and non-finite
  numbers, produce a `Failure` with `FailureKind.validation`.

## Typed events

`AnalyticsEvent` carries the name and properties as a single value, and
`captureEvent` passes it to any `Analytics` implementation:

```dart
const projectCreated = AnalyticsEvent(
  'project created',
  properties: <String, Object?>{'plan': 'pro', 'seat_count': 3},
);

await registry.read<Analytics>().captureEvent(projectCreated);
```

Store events used in several places as constants so their names and property
shapes stay consistent. Do not put PII in properties; see
[privacy-and-consent.md](privacy-and-consent.md).
