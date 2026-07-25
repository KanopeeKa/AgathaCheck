/// Target fostering session statuses (J3 / G0 §6.2).
abstract final class FosterSessionStatus {
  static const pendingAcceptance = 'pending_acceptance';
  static const preparation = 'preparation';
  static const readyToStart = 'ready_to_start';
  static const active = 'active';
  static const endPendingConfirmation = 'end_pending_confirmation';
  static const adoptionInProgress = 'adoption_in_progress';
  static const returnedToShelter = 'returned_to_shelter';
  static const transferred = 'transferred';
  static const convertedToAdoption = 'converted_to_adoption';
  static const cancelled = 'cancelled';

  static const openStatuses = {
    pendingAcceptance,
    preparation,
    readyToStart,
    active,
    endPendingConfirmation,
    adoptionInProgress,
  };

  static const terminalStatuses = {
    returnedToShelter,
    transferred,
    convertedToAdoption,
    cancelled,
  };

  static String fromLegacyStatus(String status) {
    switch (status) {
      case 'pending':
        return pendingAcceptance;
      case 'in_progress':
        return active;
      case 'waiting_adoption_confirmation':
      case 'pending_adoption_conditions':
        return adoptionInProgress;
      case 'adopted':
        return convertedToAdoption;
      case 'not_in_foster':
        return cancelled;
      default:
        return status;
    }
  }

  static bool isOpen(String sessionStatus) => openStatuses.contains(sessionStatus);

  static bool isTerminal(String sessionStatus) =>
      terminalStatuses.contains(sessionStatus);
}

abstract final class FosterSessionType {
  static const standardFoster = 'standard_foster';
  static const fosterInViewToAdopt = 'foster_in_view_to_adopt';
}

abstract final class FosterSessionEndOutcome {
  static const returnedToShelter = FosterSessionStatus.returnedToShelter;
  static const cancelled = FosterSessionStatus.cancelled;
}
