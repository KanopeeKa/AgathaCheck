import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/foster_questionnaire_template.dart';
import 'form_state.dart';

class FosterQuestionnaireFormController {
  FosterQuestionnaireFormController({
    required this.orgId,
    required this.loadTemplate,
    required this.submitQuestionnaire,
  });

  final String orgId;
  final Future<FosterQuestionnaireTemplate> Function() loadTemplate;
  final Future<FosterQuestionnaireSubmissionResult> Function({
    required List<Map<String, dynamic>> answers,
    required String generalNote,
    required bool candidateAcknowledged,
  })
  submitQuestionnaire;

  FosterQuestionnaireFormState _state = const FosterQuestionnaireFormState();
  FosterQuestionnaireFormState get state => _state;

  void Function(FosterQuestionnaireFormState state)? onStateChanged;

  Future<void> initialize() async {
    final template = await loadTemplate();
    _emit(_state.copyWith(template: template, clearValidationMessage: true));
  }

  void toggleProfileOption(String fieldId, String optionId) {
    final template = _state.template;
    if (template == null) return;

    final field = template.definition.profileFields
        .where((item) => item.id == fieldId)
        .firstOrNull;
    if (field == null) return;

    final current = _state.answerFor(fieldId);
    if (field.responseType == 'multiSelect') {
      final selected = List<String>.from(current.selectedOptions);
      if (selected.contains(optionId)) {
        selected.remove(optionId);
      } else {
        selected.add(optionId);
      }
      _updateAnswer(fieldId, current.copyWith(selectedOptions: selected));
      if (fieldId == 'PF01') {
        _syncCapacityWithSpecies(selected);
      }
      return;
    }

    _updateAnswer(fieldId, current.copyWith(singleOptionId: optionId));
  }

  void setCapacity(String speciesId, String rawValue) {
    final capacities = Map<String, int>.from(_state.capacityBySpecies());
    if (rawValue.trim().isEmpty) {
      capacities.remove(speciesId);
    } else {
      capacities[speciesId] = int.tryParse(rawValue.trim()) ?? -1;
    }
    _updateAnswer('PF05', FosterQuestionnaireAnswerDraft(value: capacities));
  }

  void setAvailabilityStart(String? calendarDate) {
    final availability = _availabilityValue();
    availability['start'] = calendarDate;
    _setAvailabilityValue(availability);
  }

  void setAvailabilityEnd(String? calendarDate) {
    final availability = _availabilityValue();
    availability['end'] = calendarDate;
    _setAvailabilityValue(availability);
  }

  void selectScreeningOption(String questionId, String optionId) {
    _updateAnswer(
      questionId,
      FosterQuestionnaireAnswerDraft(singleOptionId: optionId),
    );
  }

  void setScreeningNote(String questionId, String note) {
    final current = _state.answerFor(questionId);
    _updateAnswer(questionId, current.copyWith(note: note));
  }

  void setProfileNote(String fieldId, String note) {
    final current = _state.answerFor(fieldId);
    _updateAnswer(fieldId, current.copyWith(note: note));
  }

  void setGeneralNote(String note) {
    _emit(_state.copyWith(generalNote: note, clearValidationMessage: true));
  }

  void setCandidateAcknowledged(bool value) {
    _emit(
      _state.copyWith(
        candidateAcknowledged: value,
        clearValidationMessage: true,
      ),
    );
  }

  void goToSection(FosterQuestionnaireSection section) {
    _emit(_state.copyWith(section: section, clearValidationMessage: true));
  }

  String? validateSection(FosterQuestionnaireSection section, AppLocalizations l) {
    final template = _state.template;
    if (template == null) {
      return l.fosterQuestionnaireErrorMissingTemplate;
    }

    return switch (section) {
      FosterQuestionnaireSection.profile => _validateProfile(template, l),
      FosterQuestionnaireSection.screening => _validateScreening(template, l),
      FosterQuestionnaireSection.acknowledgement =>
        _validateAcknowledgement(l),
    };
  }

  bool advanceSection(AppLocalizations l) {
    final message = validateSection(_state.section, l);
    if (message != null) {
      _emit(_state.copyWith(validationMessage: message));
      return false;
    }

    final next = switch (_state.section) {
      FosterQuestionnaireSection.profile =>
        FosterQuestionnaireSection.screening,
      FosterQuestionnaireSection.screening =>
        FosterQuestionnaireSection.acknowledgement,
      FosterQuestionnaireSection.acknowledgement => null,
    };
    if (next == null) return false;
    _emit(_state.copyWith(section: next, clearValidationMessage: true));
    return true;
  }

  Future<String?> submit(AppLocalizations l) async {
    final acknowledgementError = _validateAcknowledgement(l);
    if (acknowledgementError != null) {
      _emit(_state.copyWith(validationMessage: acknowledgementError));
      return acknowledgementError;
    }

    for (final section in FosterQuestionnaireSection.values) {
      final message = validateSection(section, l);
      if (message != null) {
        _emit(_state.copyWith(section: section, validationMessage: message));
        return message;
      }
    }

    _emit(_state.copyWith(submitting: true, clearValidationMessage: true));
    try {
      final result = await submitQuestionnaire(
        answers: _state.buildSubmitPayload(),
        generalNote: _state.generalNote.trim(),
        candidateAcknowledged: _state.candidateAcknowledged,
      );
      _emit(
        _state.copyWith(
          submitting: false,
          submitted: true,
          submissionResult: result,
        ),
      );
      return null;
    } catch (error) {
      final message = l.fosterQuestionnaireSubmitError('$error');
      _emit(_state.copyWith(submitting: false, validationMessage: message));
      return message;
    }
  }

  String? _validateProfile(
    FosterQuestionnaireTemplate template,
    AppLocalizations l,
  ) {
    for (final field in template.definition.profileFields) {
      final draft = _state.answerFor(field.id);
      switch (field.responseType) {
        case 'multiSelect':
          if (draft.selectedOptions.isEmpty) {
            return l.fosterQuestionnaireSectionIncomplete;
          }
          if (field.id == 'PF01' &&
              draft.selectedOptions.contains('OTHER') &&
              draft.note.trim().isEmpty) {
            return l.fosterQuestionnairePf01OtherNoteRequired;
          }
        case 'singleChoice':
          if (draft.singleOptionId == null || draft.singleOptionId!.isEmpty) {
            return l.fosterQuestionnaireSectionIncomplete;
          }
        case 'numberBySpecies':
          final species = _state.selectedSpecies();
          if (species.isEmpty) {
            return l.fosterQuestionnairePf05RequiresSpecies;
          }
          final capacities = _state.capacityBySpecies();
          for (final item in species) {
            final count = capacities[item];
            if (count == null || count < 0) {
              return l.fosterQuestionnairePf05CapacityRequired;
            }
          }
        case 'availabilityAndUnavailability':
          final availability = _availabilityValue();
          if (availability['start'] == null || availability['end'] == null) {
            return l.fosterQuestionnairePf06AvailabilityRequired;
          }
      }
    }
    return null;
  }

  String? _validateScreening(
    FosterQuestionnaireTemplate template,
    AppLocalizations l,
  ) {
    for (final question in template.definition.screeningQuestions) {
      final draft = _state.answerFor(question.id);
      if (draft.singleOptionId == null || draft.singleOptionId!.isEmpty) {
        return l.fosterQuestionnaireSectionIncomplete;
      }
    }
    return null;
  }

  String? _validateAcknowledgement(AppLocalizations l) {
    if (!_state.candidateAcknowledged) {
      return l.fosterQuestionnaireAcknowledgementRequired;
    }
    return null;
  }

  Map<String, String?> _availabilityValue() {
    final raw = _state.answerFor('PF06').value;
    if (raw is Map) {
      if (raw.containsKey('start') || raw.containsKey('end')) {
        return {
          'start': raw['start']?.toString(),
          'end': raw['end']?.toString(),
        };
      }
      final periods = raw['availability'];
      if (periods is List && periods.isNotEmpty && periods.first is Map) {
        final period = periods.first as Map;
        return {
          'start': period['start']?.toString(),
          'end': period['end']?.toString(),
        };
      }
    }
    return {'start': null, 'end': null};
  }

  void _setAvailabilityValue(Map<String, String?> availability) {
    final start = availability['start'];
    final end = availability['end'];
    final value = <String, dynamic>{
      'start': start,
      'end': end,
      'availability': [
        if (start != null && end != null) {'start': start, 'end': end},
      ],
      'unavailability': const <Map<String, String>>[],
    };
    _updateAnswer('PF06', FosterQuestionnaireAnswerDraft(value: value));
  }

  void _syncCapacityWithSpecies(List<String> species) {
    final capacities = Map<String, int>.from(_state.capacityBySpecies());
    capacities.removeWhere((key, _) => !species.contains(key));
    _updateAnswer('PF05', FosterQuestionnaireAnswerDraft(value: capacities));
  }

  void _updateAnswer(String questionId, FosterQuestionnaireAnswerDraft draft) {
    final answers = Map<String, FosterQuestionnaireAnswerDraft>.from(
      _state.answers,
    );
    answers[questionId] = draft;
    _emit(_state.copyWith(answers: answers, clearValidationMessage: true));
  }

  void _emit(FosterQuestionnaireFormState next) {
    _state = next;
    onStateChanged?.call(_state);
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
