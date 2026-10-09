import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Payload when saving a care add form opened from a pending recommendation.
class CareSuggestionFormAcceptRequest {
  const CareSuggestionFormAcceptRequest({
    required this.petId,
    required this.recommendationId,
    required this.name,
    required this.frequencyWire,
    required this.frequencyInterval,
  });

  final String petId;
  final String recommendationId;
  final String name;
  final String frequencyWire;
  final int frequencyInterval;
}

class CareSuggestionFormAcceptResult {
  const CareSuggestionFormAcceptResult({this.healthEntryId});

  final String? healthEntryId;
}

typedef CareSuggestionFormAcceptHandler =
    Future<CareSuggestionFormAcceptResult> Function(
      Ref ref,
      CareSuggestionFormAcceptRequest request,
    );

/// Wired in [main] from care_intelligence; null only in tests without override.
final careSuggestionFormAcceptHandlerProvider =
    Provider<CareSuggestionFormAcceptHandler?>((ref) => null);
