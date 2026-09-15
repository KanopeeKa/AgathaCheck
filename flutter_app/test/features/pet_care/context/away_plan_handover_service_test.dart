import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_care/context/data/services/away_plan_handover_service.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  test('handover note is passed to PDF verbatim (D-AWAY-008)', () {
    const verbatimNote =
        'Feed twice daily - verbatim line 1\n**not parsed** <script>alert(1)</script>';
    expect(AwayPlanHandoverService.handoverNoteForPdf(verbatimNote), verbatimNote);
    expect(AwayPlanHandoverService.handoverNoteForPdf(null), '');
  });

  test('generateHandoverPdf includes handover note section when note is set', () async {
    const verbatimNote = 'Gate code: 4821 — do not share';
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    final service = AwayPlanHandoverService();
    final bytes = await service.generateHandoverPdf(
      document: AwayPlanHandoverDocument(
        title: l.careContextAwayPlanTitle,
        dateRangeLabel: 'Oct 1, 2026 to Oct 5, 2026',
        petNamesLabel: 'Luna',
        carerCoverageSummary: l.awayPlanningCarerCoverageAllHaveCarers,
        careCoverageSummary: l.careContextCoverageNothingScheduled,
        handoverNote: verbatimNote,
        petSections: const [
          AwayPlanHandoverPetSection(
            petName: 'Luna',
            carerLabel: 'Tom · No AgathaTrack access',
            routineLines: const [],
            datedLines: const [],
            indeterminateLines: const [],
          ),
        ],
      ),
      l: l,
    );

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(500));
  });
}
