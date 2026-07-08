class OrgHomeHiddenPet {
  const OrgHomeHiddenPet({
    required this.petId,
    required this.petName,
    this.hiddenAt,
  });

  final String petId;
  final String petName;
  final DateTime? hiddenAt;
}
