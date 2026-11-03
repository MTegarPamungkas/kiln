/// Parsed Cache-Control directives used by the cache policy.
final class CacheControl {
  const CacheControl({
    this.noStore = false,
    this.noCache = false,
    this.mustRevalidate = false,
    this.immutable = false,
    this.maxAge,
    this.staleWhileRevalidate,
  });

  final bool noStore;
  final bool noCache;
  final bool mustRevalidate;
  final bool immutable;
  final Duration? maxAge;
  final Duration? staleWhileRevalidate;
}

/// Parses the Cache-Control response header.
final class CacheControlParser {
  const CacheControlParser();

  CacheControl parse(String? header) {
    if (header == null || header.trim().isEmpty) {
      return const CacheControl();
    }
    var noStore = false;
    var noCache = false;
    var mustRevalidate = false;
    var immutable = false;
    Duration? maxAge;
    Duration? staleWhileRevalidate;

    for (final rawDirective in header.split(',')) {
      final directive = rawDirective.trim().toLowerCase();
      if (directive.isEmpty) {
        continue;
      }
      final separator = directive.indexOf('=');
      final name = separator < 0
          ? directive
          : directive.substring(0, separator).trim();
      final value = separator < 0
          ? null
          : directive.substring(separator + 1).trim();
      switch (name) {
        case 'no-store':
          noStore = true;
        case 'no-cache':
          noCache = true;
        case 'must-revalidate':
          mustRevalidate = true;
        case 'immutable':
          immutable = true;
        case 'max-age':
          final seconds = int.tryParse(value ?? '');
          if (seconds != null && seconds >= 0) {
            maxAge = Duration(seconds: seconds);
          }
        case 'stale-while-revalidate':
          final seconds = int.tryParse(value ?? '');
          if (seconds != null && seconds >= 0) {
            staleWhileRevalidate = Duration(seconds: seconds);
          }
      }
    }

    return CacheControl(
      noStore: noStore,
      noCache: noCache,
      mustRevalidate: mustRevalidate,
      immutable: immutable,
      maxAge: maxAge,
      staleWhileRevalidate: staleWhileRevalidate,
    );
  }
}
