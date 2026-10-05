/// Temporal buckets for open care items on the Pet Profile, All care, and dashboard.
enum CareTemporalGroup {
  /// Overdue or otherwise needs carer attention (e.g. time to follow up).
  needsAttention,

  /// Due today and not yet done.
  today,

  /// Due after today, within the entry's reminder horizon.
  upcoming,
}
