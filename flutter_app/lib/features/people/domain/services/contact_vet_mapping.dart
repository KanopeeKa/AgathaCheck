import '../../../vet/domain/entities/vet.dart';
import '../entities/contact_detail.dart';

/// Maps a People contact to the legacy [Vet] shape used by pet PDF reports (B7).
Vet? vetFromContactDetail(ContactDetail? detail) {
  if (detail == null) return null;
  return Vet(
    id: detail.legacyVetId ?? detail.id,
    name: detail.name,
    phone: detail.phone ?? '',
    email: detail.email ?? '',
    address: detail.address ?? '',
    website: detail.website ?? '',
  );
}
