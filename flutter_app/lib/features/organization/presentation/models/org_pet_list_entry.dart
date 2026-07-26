import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/archived_pet.dart';
import '../utils/org_pets_care_utils.dart';

/// A row on the organisation pets screen — live inventory or archived record.
class OrgPetListEntry {
  const OrgPetListEntry.live({
    required this.pet,
    this.fosterEndDate,
    this.attentionReason,
  }) : archivedPet = null;

  const OrgPetListEntry.archived({required this.archivedPet})
    : pet = null,
      fosterEndDate = null,
      attentionReason = null;

  final Pet? pet;
  final ArchivedPet? archivedPet;
  final DateTime? fosterEndDate;
  final OrgPetAttentionReason? attentionReason;

  bool get isLive => pet != null;
  bool get isArchived => archivedPet != null;
  bool get isShadow => archivedPet?.hasShadowSnapshot ?? false;

  String get id => pet?.id ?? archivedPet!.id;
  String get name => pet?.name ?? archivedPet!.petName;
  String get species => pet?.species ?? archivedPet!.species;
  String? get fosterName => pet?.fosterName;
  bool get passedAway => pet?.passedAway ?? false;

  bool get isAdoptedArchive {
    final type = archivedPet?.transferType ?? '';
    return type == 'adoption' || type == 'direct_adopt';
  }
}
