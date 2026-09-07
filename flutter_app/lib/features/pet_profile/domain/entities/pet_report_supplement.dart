/// Minimal report DTOs for PDF generation without frozen-domain imports.

class PetReportFamilyEvent {
  const PetReportFamilyEvent({
    required this.assignedDisplay,
    required this.fromDate,
    this.toDate,
    this.notes = '',
  });

  final String assignedDisplay;
  final DateTime fromDate;
  final DateTime? toDate;
  final String notes;
}

class PetReportFosterPlacement {
  const PetReportFosterPlacement({
    required this.fosterName,
    required this.fosterEmail,
    this.startDate,
    this.endDate,
    this.adoptionConditions = '',
    this.notes = '',
    this.isPending = false,
    this.isInProgress = false,
    this.isPendingConditions = false,
    this.isWaitingAdoption = false,
    this.isAdopted = false,
  });

  final String fosterName;
  final String fosterEmail;
  final DateTime? startDate;
  final DateTime? endDate;
  final String adoptionConditions;
  final String notes;
  final bool isPending;
  final bool isInProgress;
  final bool isPendingConditions;
  final bool isWaitingAdoption;
  final bool isAdopted;
}
