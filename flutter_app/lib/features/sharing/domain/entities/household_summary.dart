class HouseholdSummary {
  const HouseholdSummary({
    required this.id,
    required this.name,
    required this.myAccessTier,
    required this.myIsOrganiser,
  });

  final String id;
  final String name;
  final String myAccessTier;
  final bool myIsOrganiser;
}
