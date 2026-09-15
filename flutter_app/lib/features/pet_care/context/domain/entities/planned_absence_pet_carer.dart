class PlannedAbsencePetCarer {
  const PlannedAbsencePetCarer({
    required this.petId,
    this.carerKind,
    this.carerUserId,
    this.carerName,
    this.carerNote,
    this.carerRemoved = false,
  });

  final String petId;
  final String? carerKind;
  final String? carerUserId;
  final String? carerName;
  final String? carerNote;
  final bool carerRemoved;

  bool get hasCarer =>
      !carerRemoved &&
      carerKind != null &&
      carerKind!.isNotEmpty &&
      (carerKind != 'note_only' || (carerName != null && carerName!.isNotEmpty));
}
