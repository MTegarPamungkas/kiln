import 'dart:async';

/// Categories the user can consent to independently.
enum ConsentCategory { analytics, crashReports }

/// Opt-in consent state. Nothing is sent until a category is granted.
final class ConsentController {
  ConsentController({bool analytics = false, bool crashReports = false})
    : _decisions = <ConsentCategory, bool>{
        ConsentCategory.analytics: analytics,
        ConsentCategory.crashReports: crashReports,
      };

  final Map<ConsentCategory, bool> _decisions;
  final StreamController<ConsentCategory> _changes =
      StreamController<ConsentCategory>.broadcast(sync: true);

  Stream<ConsentCategory> get changes => _changes.stream;

  Map<ConsentCategory, bool> get decisions =>
      Map<ConsentCategory, bool>.unmodifiable(_decisions);

  bool isGranted(ConsentCategory category) => _decisions[category] ?? false;

  bool get hasAnyConsent => _decisions.values.any((granted) => granted);

  void grant(ConsentCategory category) => set(category, true);

  void deny(ConsentCategory category) => set(category, false);

  void set(ConsentCategory category, bool granted) {
    if (_decisions[category] == granted) {
      return;
    }
    _decisions[category] = granted;
    _changes.add(category);
  }

  void reset() {
    for (final category in ConsentCategory.values) {
      set(category, false);
    }
  }

  Future<void> dispose() => _changes.close();
}
