import '../../../../care_taxonomy/domain/care_planning_mode.dart';
import '../../../../care_taxonomy/domain/care_setting.dart';

/// Whether to show the §10.1 unplanned vet save health-issue prompt.
bool shouldPromptUnplannedVetSave({
  required CareSetting careSetting,
  required CarePlanningMode carePlanning,
  String? healthIssueId,
}) {
  return careSetting == CareSetting.vet &&
      carePlanning == CarePlanningMode.unplanned &&
      healthIssueId == null;
}

/// Whether to show the §10.2 planned vet completion health-issue prompt.
bool shouldPromptPlannedVetCompletion({
  required CareSetting careSetting,
  required CarePlanningMode carePlanning,
  String? healthIssueId,
}) {
  return careSetting == CareSetting.vet &&
      carePlanning == CarePlanningMode.planned &&
      healthIssueId == null;
}
