/// Inputs that must have a value before an occurrence can be completed
/// (D-CIE-031). Only required inputs; today only weight monitoring.
///
/// Adding one later = one enum value here + one field widget + server
/// validation. The server stays the authority.
library;

const kWeightMonitoringFamily = 'weight_monitoring';

enum CompletionRequirement { weight }

/// Which completion route the server expects (§18.6.2).
enum CompletionEndpoint { complete, completeWeight }

List<CompletionRequirement> completionRequirementsFor(String? careFamily) {
  if (careFamily == kWeightMonitoringFamily) {
    return const [CompletionRequirement.weight];
  }
  return const [];
}

CompletionEndpoint completionEndpointFor(String? careFamily) {
  return careFamily == kWeightMonitoringFamily
      ? CompletionEndpoint.completeWeight
      : CompletionEndpoint.complete;
}

/// Values entered for the requirements.
class CompletionInputs {
  const CompletionInputs({this.weightValue, this.weightUnit = 'kg'});

  final double? weightValue;
  final String weightUnit;
}

/// Requirements of [careFamily] that [inputs] does not satisfy yet.
List<CompletionRequirement> missingRequirements(
  String? careFamily,
  CompletionInputs inputs,
) {
  return completionRequirementsFor(careFamily)
      .where((requirement) {
        switch (requirement) {
          case CompletionRequirement.weight:
            final value = inputs.weightValue;
            return value == null || !value.isFinite || value <= 0;
        }
      })
      .toList(growable: false);
}
