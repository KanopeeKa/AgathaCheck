import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_planning_mode.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_setting.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_issue_prompt/health_issue_prompt_eligibility.dart';

void main() {
  group('shouldPromptUnplannedVetSave', () {
    test('returns true for unplanned vet entry without health issue', () {
      expect(
        shouldPromptUnplannedVetSave(
          careSetting: CareSetting.vet,
          carePlanning: CarePlanningMode.unplanned,
          healthIssueId: null,
        ),
        isTrue,
      );
    });

    test('returns false when health issue already linked', () {
      expect(
        shouldPromptUnplannedVetSave(
          careSetting: CareSetting.vet,
          carePlanning: CarePlanningMode.unplanned,
          healthIssueId: 'issue-1',
        ),
        isFalse,
      );
    });

    test('returns false for home setting', () {
      expect(
        shouldPromptUnplannedVetSave(
          careSetting: CareSetting.home,
          carePlanning: CarePlanningMode.unplanned,
        ),
        isFalse,
      );
    });

    test('returns false for planned vet entry', () {
      expect(
        shouldPromptUnplannedVetSave(
          careSetting: CareSetting.vet,
          carePlanning: CarePlanningMode.planned,
        ),
        isFalse,
      );
    });
  });

  group('shouldPromptPlannedVetCompletion', () {
    test('returns true for planned vet entry without health issue', () {
      expect(
        shouldPromptPlannedVetCompletion(
          careSetting: CareSetting.vet,
          carePlanning: CarePlanningMode.planned,
          healthIssueId: null,
        ),
        isTrue,
      );
    });

    test('returns false when health issue already linked', () {
      expect(
        shouldPromptPlannedVetCompletion(
          careSetting: CareSetting.vet,
          carePlanning: CarePlanningMode.planned,
          healthIssueId: 'issue-1',
        ),
        isFalse,
      );
    });

    test('returns false for unplanned vet entry', () {
      expect(
        shouldPromptPlannedVetCompletion(
          careSetting: CareSetting.vet,
          carePlanning: CarePlanningMode.unplanned,
        ),
        isFalse,
      );
    });
  });
}
