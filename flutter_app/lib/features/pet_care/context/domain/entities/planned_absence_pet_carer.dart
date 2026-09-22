class PlannedAbsencePetCarer {
  const PlannedAbsencePetCarer({
    required this.petId,
    this.carerKind,
    this.carerUserId,
    this.carerName,
    this.carerNote,
    this.carerRemoved = false,
    this.petNote,
  });

  final String petId;
  final String? carerKind;
  final String? carerUserId;
  final String? carerName;
  final String? carerNote;
  final bool carerRemoved;

  /// About caring for this pet (feeding, meds, quirks) — independent of
  /// [carerKind], unlike [carerNote] which is only ever set for `note_only`
  /// carers and describes the person, not the pet.
  final String? petNote;

  bool get hasCarer {
    if (carerRemoved) return false;
    if (carerKind == null || carerKind!.isEmpty) return false;
    if (carerKind == 'note_only') {
      return (carerName ?? '').trim().isNotEmpty;
    }
    return true;
  }
}
