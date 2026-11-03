# Interceptors

The extension opens `http.interceptors` with the item type `HttpMiddleware`.
Contributors add OrderedSlot items from the Registry; they never import dio.

```dart
final slot = registry
    .read<SlotRegistry>()
    .open<HttpMiddleware>(SlotNames.httpInterceptors);
slot.add(MyMiddleware(), priority: 20, owner: 'my_extension');
```

Middleware wraps the transport. The outer middleware receives the request
first and the response last.
