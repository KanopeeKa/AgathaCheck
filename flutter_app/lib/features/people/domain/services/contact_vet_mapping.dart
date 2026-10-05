import '../entities/contact_detail.dart';
import '../entities/pet_report_vet_details.dart';

PetReportVetDetails? petReportVetFromContactDetail(ContactDetail? detail) {
  if (detail == null) return null;
  return PetReportVetDetails(
    name: detail.name,
    phone: detail.phone ?? '',
    email: detail.email ?? '',
    address: detail.address ?? '',
  );
}
