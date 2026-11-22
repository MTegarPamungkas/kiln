/// Whether a preference change survives a restart.
///
/// Controllers that persist an optional user choice (theme mode, locale) report
/// this instead of hiding a storage failure behind a plain success. The choice
/// still applies for the current session; only durability is affected.
enum PersistOutcome {
  /// The change was written and will be restored on the next launch.
  persisted,

  /// The change applies now but could not be saved; it is lost on restart.
  sessionOnly,

  /// No storage backend is configured, so the change is never saved.
  notConfigured;

  /// Whether the change is durable.
  bool get isPersisted => this == PersistOutcome.persisted;
}
