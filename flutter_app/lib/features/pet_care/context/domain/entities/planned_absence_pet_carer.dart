class PlannedAbsencePetCarer {
  const PlannedAbsencePetCarer({
    required this.petId,
    this.carerKind,
    this.carerUserId,
    this.carerName,
    this.carerNote,
    this.contactId,
    this.carerState = 'unset',
    this.carerRemoved = false,
    this.petNote,
  });

  final String petId;
  final String? carerKind;
  final String? carerUserId;
  final String? carerName;
  final String? carerNote;
  final String? contactId;

  /// `unset` | `set` | `unavailable` — server-authoritative (People phase 2).
  final String carerState;

  /// True when [carerState] is `unavailable` (legacy `carer_removed` alias).
  final bool carerRemoved;

  /// About caring for this pet (feeding, meds, quirks) — independent of
  /// [carerKind], unlike [carerNote] which is only ever set for `note_only`
  /// carers and describes the person, not the pet.
  final String? petNote;

  bool get hasCarer => carerState == 'set';

  bool get isCarerUnavailable =>
      carerState == 'unavailable' || carerRemoved;
}
