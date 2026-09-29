/// Temporal buckets for open care items on the Pet Profile, All care, and dashboard.
enum CareTemporalGroup {
  /// Overdue or otherwise needs carer attention (e.g. time to follow up).
  needsAttention,

  /// Due today and not yet done.
  today,

  /// Next scheduled occurrence after today (includes dates outside the reminder window).
  upcoming,
}
