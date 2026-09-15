class CarerCoverageFact {
  const CarerCoverageFact({
    required this.state,
    required this.petsWithCarer,
    required this.petsTotal,
    required this.copyKey,
  });

  final String state;
  final int petsWithCarer;
  final int petsTotal;
  final String copyKey;
}

class CareCoverageFact {
  const CareCoverageFact({
    required this.policyVersion,
    required this.coverageState,
    required this.reasonCodes,
    required this.reassuranceAvailable,
    required this.copyKey,
    this.copyCount,
  });

  final String policyVersion;
  final String coverageState;
  final List<String> reasonCodes;
  final bool reassuranceAvailable;
  final String copyKey;
  final int? copyCount;
}

class AwayPlanReadiness {
  const AwayPlanReadiness({
    required this.carerCoverage,
    required this.careCoverage,
  });

  final CarerCoverageFact carerCoverage;
  final CareCoverageFact careCoverage;
}
