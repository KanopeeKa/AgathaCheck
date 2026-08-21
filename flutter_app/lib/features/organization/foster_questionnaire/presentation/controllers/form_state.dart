import '../../domain/entities/foster_questionnaire_template.dart';

enum FosterQuestionnaireSection { profile, screening, acknowledgement }

class FosterQuestionnaireAnswerDraft {
  const FosterQuestionnaireAnswerDraft({
    this.selectedOptions = const [],
    this.singleOptionId,
    this.value,
    this.note = '',
  });

  final List<String> selectedOptions;
  final String? singleOptionId;
  final dynamic value;
  final String note;

  FosterQuestionnaireAnswerDraft copyWith({
    List<String>? selectedOptions,
    String? singleOptionId,
    dynamic value,
    String? note,
    bool clearSingleOptionId = false,
    bool clearValue = false,
  }) {
    return FosterQuestionnaireAnswerDraft(
      selectedOptions: selectedOptions ?? this.selectedOptions,
      singleOptionId:
          clearSingleOptionId ? null : (singleOptionId ?? this.singleOptionId),
      value: clearValue ? null : (value ?? this.value),
      note: note ?? this.note,
    );
  }
}

class FosterQuestionnaireFormState {
  const FosterQuestionnaireFormState({
    this.template,
    this.answers = const {},
    this.generalNote = '',
    this.candidateAcknowledged = false,
    this.section = FosterQuestionnaireSection.profile,
    this.submitting = false,
    this.submitted = false,
    this.submissionResult,
    this.validationMessage = '',
  });

  final FosterQuestionnaireTemplate? template;
  final Map<String, FosterQuestionnaireAnswerDraft> answers;
  final String generalNote;
  final bool candidateAcknowledged;
  final FosterQuestionnaireSection section;
  final bool submitting;
  final bool submitted;
  final FosterQuestionnaireSubmissionResult? submissionResult;
  final String validationMessage;

  FosterQuestionnaireFormState copyWith({
    FosterQuestionnaireTemplate? template,
    Map<String, FosterQuestionnaireAnswerDraft>? answers,
    String? generalNote,
    bool? candidateAcknowledged,
    FosterQuestionnaireSection? section,
    bool? submitting,
    bool? submitted,
    FosterQuestionnaireSubmissionResult? submissionResult,
    String? validationMessage,
    bool clearValidationMessage = false,
  }) {
    return FosterQuestionnaireFormState(
      template: template ?? this.template,
      answers: answers ?? this.answers,
      generalNote: generalNote ?? this.generalNote,
      candidateAcknowledged:
          candidateAcknowledged ?? this.candidateAcknowledged,
      section: section ?? this.section,
      submitting: submitting ?? this.submitting,
      submitted: submitted ?? this.submitted,
      submissionResult: submissionResult ?? this.submissionResult,
      validationMessage: clearValidationMessage
          ? ''
          : (validationMessage ?? this.validationMessage),
    );
  }

  FosterQuestionnaireAnswerDraft answerFor(String questionId) =>
      answers[questionId] ?? const FosterQuestionnaireAnswerDraft();

  List<String> selectedSpecies() => answerFor('PF01').selectedOptions;

  Map<String, int> capacityBySpecies() {
    final raw = answerFor('PF05').value;
    if (raw is! Map) return {};
    return raw.map(
      (key, value) => MapEntry(key.toString(), (value as num).toInt()),
    );
  }

  List<Map<String, dynamic>> buildSubmitPayload() {
    final payload = <Map<String, dynamic>>[];
    for (final entry in answers.entries) {
      final draft = entry.value;
      final row = <String, dynamic>{'question_id': entry.key};
      if (draft.singleOptionId != null && draft.singleOptionId!.isNotEmpty) {
        row['option_id'] = draft.singleOptionId;
      }
      if (draft.selectedOptions.isNotEmpty) {
        row['value'] = draft.selectedOptions;
      } else if (draft.value != null) {
        row['value'] = entry.key == 'PF06'
            ? _normalizedAvailabilityValue(draft.value)
            : draft.value;
      }
      if (draft.note.trim().isNotEmpty) {
        row['note'] = draft.note.trim();
      }
      payload.add(row);
    }
    return payload;
  }

  Map<String, dynamic> _normalizedAvailabilityValue(dynamic raw) {
    if (raw is! Map) {
      return const {
        'availability': <Map<String, String>>[],
        'unavailability': <Map<String, String>>[],
      };
    }
    final availability = raw['availability'];
    if (availability is List && availability.isNotEmpty) {
      return {
        'availability': availability,
        'unavailability': raw['unavailability'] ?? const [],
      };
    }
    final start = raw['start']?.toString();
    final end = raw['end']?.toString();
    return {
      'availability': [
        if (start != null && end != null) {'start': start, 'end': end},
      ],
      'unavailability': raw['unavailability'] ?? const [],
    };
  }
}
