/// When a weight counts as a weigh-in, the API includes routine metadata.
class WeightFulfils {
  const WeightFulfils({
    required this.entryId,
    required this.entryName,
    required this.occurrenceId,
    required this.scheduledDate,
  });

  final String entryId;
  final String entryName;
  final String occurrenceId;
  final DateTime scheduledDate;
}
