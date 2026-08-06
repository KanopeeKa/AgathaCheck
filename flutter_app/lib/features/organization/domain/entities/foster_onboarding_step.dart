/// Foster onboarding timeline step on a person profile (D-v4-FOSTER-3).
enum FosterOnboardingStepState {
  complete,
  current,
  notStarted,
  issue;

  static FosterOnboardingStepState fromWire(String? value) {
    switch (value) {
      case 'complete': return FosterOnboardingStepState.complete;
      case 'current': return FosterOnboardingStepState.current;
      case 'issue': return FosterOnboardingStepState.issue;
      default: return FosterOnboardingStepState.notStarted;
    }
  }

  String get wire => switch (this) {
    FosterOnboardingStepState.complete => 'complete',
    FosterOnboardingStepState.current => 'current',
    FosterOnboardingStepState.issue => 'issue',
    FosterOnboardingStepState.notStarted => 'not_started',
  };
}

class FosterOnboardingStep {
  const FosterOnboardingStep({
    required this.key,
    required this.label,
    required this.state,
    this.deferred = false,
    this.canConfirm = true,
  });

  final String key;
  final String label;
  final FosterOnboardingStepState state;
  final bool deferred;
  final bool canConfirm;

  bool get isComplete => state == FosterOnboardingStepState.complete;

  factory FosterOnboardingStep.fromJson(Map<String, dynamic> json) => FosterOnboardingStep(
    key: json['key']?.toString() ?? '',
    label: json['label']?.toString() ?? '',
    state: FosterOnboardingStepState.fromWire(json['state']?.toString()),
    deferred: json['deferred'] == true,
    canConfirm: json['can_confirm'] != false,
  );
}

class FosterOnboardingStatus {
  const FosterOnboardingStatus({required this.resourceId, required this.steps});
  final String resourceId;
  final List<FosterOnboardingStep> steps;

  factory FosterOnboardingStatus.fromJson(Map<String, dynamic> json) => FosterOnboardingStatus(
    resourceId: json['resource_id']?.toString() ?? '',
    steps: (json['steps'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => FosterOnboardingStep.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
}
