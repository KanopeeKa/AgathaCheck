class SessionViewerRole {
  static const fosterParticipant = 'foster_participant';
  static const shelterOperator = 'shelter_operator';
  static const shelterObserver = 'shelter_observer';
  static const readOnlyHistory = 'read_only_history';
}

class SessionAction {
  static const acceptInvite = 'accept_invite';
  static const declineInvite = 'decline_invite';
  static const confirmFosterStart = 'confirm_foster_start';
  static const confirmShelterStart = 'confirm_shelter_start';
  static const transitionPreparation = 'transition_preparation';
  static const transitionReadyToStart = 'transition_ready_to_start';
  static const updateChecklistItem = 'update_checklist_item';
  static const registerExport = 'register_export';
  static const requestEnd = 'request_end';
  static const completeEndReturned = 'complete_end_returned';
  static const completeEndCancelled = 'complete_end_cancelled';
  static const startAdoptionJourney = 'start_adoption_journey';
  static const expediteVisitAdoption = 'expedite_visit_adoption';
  static const confirmAdoption = 'confirm_adoption';
  static const completeAdoptionConditions = 'complete_adoption_conditions';
  static const cancelAdoption = 'cancel_adoption';
  static const contactCounterparty = 'contact_counterparty';
  static const editSessionMetadata = 'edit_session_metadata';
}

class SessionViewerContext {
  const SessionViewerContext({
    required this.role,
    this.allowedActions = const [],
  });

  final String role;
  final List<String> allowedActions;

  bool can(String action) => allowedActions.contains(action);

  factory SessionViewerContext.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SessionViewerContext(role: SessionViewerRole.shelterOperator);
    }
    final actions = json['allowed_actions'];
    return SessionViewerContext(
      role: json['role']?.toString() ?? SessionViewerRole.shelterOperator,
      allowedActions: actions is List
          ? actions.map((e) => e.toString()).toList()
          : const [],
    );
  }
}
