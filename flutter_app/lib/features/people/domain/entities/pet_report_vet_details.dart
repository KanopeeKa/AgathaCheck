/// Primary vet coordinates for pet PDF reports (B7).
class PetReportVetDetails {
  const PetReportVetDetails({
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
  });

  final String name;
  final String phone;
  final String email;
  final String address;
}
