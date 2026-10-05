import 'weight_entry.dart';

class WeightFulfilmentOutcome {
  const WeightFulfilmentOutcome({
    required this.careEntryId,
    required this.undoToken,
    this.routineName,
  });

  final String careEntryId;
  final String undoToken;
  final String? routineName;
}

class WeightSaveOutcome {
  const WeightSaveOutcome({required this.entry, this.fulfilment});

  final WeightEntry entry;
  final WeightFulfilmentOutcome? fulfilment;
}

class WeightReopenedOccurrence {
  const WeightReopenedOccurrence({
    required this.careEntryId,
    required this.occurrenceId,
  });

  final String careEntryId;
  final String occurrenceId;
}

class WeightDeleteOutcome {
  const WeightDeleteOutcome({this.reopened});

  final WeightReopenedOccurrence? reopened;
}
