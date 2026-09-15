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

  bool get hasCarer {
    if (carerRemoved) return false;
    if (carerKind == null || carerKind!.isEmpty) return false;
    if (carerKind == 'note_only') {
      return (carerName ?? '').trim().isNotEmpty;
    }
    return true;
  }
}
