class WeightFulfilmentCandidate {
  const WeightFulfilmentCandidate({
    required this.entryId,
    required this.entryName,
    required this.occurrenceId,
    required this.scheduledDate,
    required this.status,
  });

  final String entryId;
  final String entryName;
  final String occurrenceId;
  final DateTime scheduledDate;
  final String status;
}

class WeightFulfilmentCandidates {
  const WeightFulfilmentCandidates({
    required this.date,
    required this.candidates,
    this.defaultOccurrenceId,
  });

  final DateTime date;
  final List<WeightFulfilmentCandidate> candidates;
  final String? defaultOccurrenceId;
}
