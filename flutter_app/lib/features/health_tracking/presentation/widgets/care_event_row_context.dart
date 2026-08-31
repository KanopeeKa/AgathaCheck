/// Where a [CareEventRow] is shown — controls metadata lines only.
enum CareEventRowContext {
  /// Guardian dashboard Care preview and global `/g/events` list.
  dashboard,

  /// Pet profile Due and overdue section (pet name omitted from metadata).
  pet,
}
