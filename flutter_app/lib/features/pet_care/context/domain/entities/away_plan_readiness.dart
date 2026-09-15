class AwayPlanTileCopy {
  const AwayPlanTileCopy({required this.source, required this.copyKey, this.copyParams});
  final String source; final String copyKey; final Map<String, int>? copyParams;
}
class AwayPlanReadiness {
  const AwayPlanReadiness({required this.tileCopy});
  final AwayPlanTileCopy tileCopy;
}
