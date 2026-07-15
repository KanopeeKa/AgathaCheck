/// Which pets/events to show on the events dashboard.
enum HealthEventsScope {
  /// All pets the user can access (legacy `/health`).
  all,

  /// Guardian shell: owned, shared, and fostered pets — no org inventory.
  guardian,

  /// Organisation shell: org inventory pets only.
  organization,
}
