# kiln_testing

Fake, contract suite, dan harness untuk aplikasi serta extension Kiln.

```dart
final registry = createTestRegistry();
final storage = InMemoryStorage();
final client = FakeHttpClient();
```

Contract suite memastikan setiap implementasi kontrak yang sama bisa saling
menggantikan. Harness menyediakan `pumpApp`, matcher `Result`, async helper, dan
golden helper.

Lihat [docs/extensions/testing-extensions.md](../../docs/extensions/testing-extensions.md).
