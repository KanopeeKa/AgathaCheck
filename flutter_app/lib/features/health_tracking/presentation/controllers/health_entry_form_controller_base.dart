import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'health_entry_form_outcomes.dart';
import 'health_entry_form_state.dart';

abstract class HealthEntryFormControllerBase
    extends StateNotifier<HealthEntryFormState> {
  HealthEntryFormControllerBase(super.initialState);

  Ref get formRef;
  String? get entryId;

  /// Set when the form was opened from a care suggestion (accept via respond).
  String? get careRecommendationId => null;

  void markCareFamilyValidationAttempted();
  HealthEntryMarkCompletedPrompt? markCompletedPromptIfNeeded();
  void applyMarkCompleted(bool markCompleted);
  List<String>? effectiveScheduleTimesForSubmit();
}
