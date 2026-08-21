class FosterQuestionnaireTemplate {
  const FosterQuestionnaireTemplate({
    required this.version,
    required this.definition,
    required this.settings,
  });

  final String version;
  final FosterQuestionnaireDefinition definition;
  final FosterQuestionnaireSettings settings;

  factory FosterQuestionnaireTemplate.fromJson(Map<String, dynamic> json) {
    return FosterQuestionnaireTemplate(
      version: json['version']?.toString() ?? '',
      definition: FosterQuestionnaireDefinition.fromJson(
        Map<String, dynamic>.from(json['definition'] as Map? ?? {}),
      ),
      settings: FosterQuestionnaireSettings.fromJson(
        Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
      ),
    );
  }
}

class FosterQuestionnaireSettings {
  const FosterQuestionnaireSettings({
    required this.minimumAge,
    required this.lightTouchReview,
  });

  final int minimumAge;
  final bool lightTouchReview;

  factory FosterQuestionnaireSettings.fromJson(Map<String, dynamic> json) {
    return FosterQuestionnaireSettings(
      minimumAge: (json['minimum_age'] as num?)?.toInt() ?? 21,
      lightTouchReview: json['light_touch_review'] == true,
    );
  }
}

class FosterQuestionnaireDefinition {
  const FosterQuestionnaireDefinition({
    required this.version,
    required this.candidateAcknowledgement,
    required this.profileFields,
    required this.screeningQuestions,
  });

  final String version;
  final String candidateAcknowledgement;
  final List<FosterProfileField> profileFields;
  final List<FosterScreeningQuestion> screeningQuestions;

  factory FosterQuestionnaireDefinition.fromJson(Map<String, dynamic> json) {
    return FosterQuestionnaireDefinition(
      version: json['version']?.toString() ?? '',
      candidateAcknowledgement:
          json['candidateAcknowledgement']?.toString() ?? '',
      profileFields: (json['profileFields'] as List? ?? [])
          .map(
            (item) => FosterProfileField.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      screeningQuestions: (json['screeningQuestions'] as List? ?? [])
          .map(
            (item) => FosterScreeningQuestion.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class FosterProfileField {
  const FosterProfileField({
    required this.id,
    required this.code,
    required this.responseType,
    required this.required,
    this.options = const [],
  });

  final String id;
  final String code;
  final String responseType;
  final bool required;
  final List<dynamic> options;

  factory FosterProfileField.fromJson(Map<String, dynamic> json) {
    return FosterProfileField(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      responseType: json['responseType']?.toString() ?? '',
      required: json['required'] == true,
      options: List<dynamic>.from(json['options'] as List? ?? []),
    );
  }
}

class FosterScreeningQuestion {
  const FosterScreeningQuestion({
    required this.id,
    required this.code,
    required this.required,
    required this.options,
    this.adminNoteRequiredIf,
  });

  final String id;
  final String code;
  final bool required;
  final List<FosterScreeningOption> options;
  final String? adminNoteRequiredIf;

  factory FosterScreeningQuestion.fromJson(Map<String, dynamic> json) {
    return FosterScreeningQuestion(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      required: json['required'] == true,
      adminNoteRequiredIf: json['adminNoteRequiredIf']?.toString(),
      options: (json['options'] as List? ?? [])
          .map(
            (item) => FosterScreeningOption.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class FosterScreeningOption {
  const FosterScreeningOption({required this.id, required this.outcome});

  final String id;
  final String outcome;

  factory FosterScreeningOption.fromJson(Map<String, dynamic> json) {
    return FosterScreeningOption(
      id: json['id']?.toString() ?? '',
      outcome: json['outcome']?.toString() ?? '',
    );
  }
}

class FosterQuestionnaireSubmissionResult {
  const FosterQuestionnaireSubmissionResult({
    required this.submissionId,
    required this.result,
    required this.q02BMandatoryFollowup,
  });

  final String submissionId;
  final String result;
  final bool q02BMandatoryFollowup;

  factory FosterQuestionnaireSubmissionResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final submission = Map<String, dynamic>.from(json['submission'] as Map);
    return FosterQuestionnaireSubmissionResult(
      submissionId: submission['id']?.toString() ?? '',
      result: submission['result']?.toString() ?? '',
      q02BMandatoryFollowup: submission['q02_b_mandatory_followup'] == true,
    );
  }
}
