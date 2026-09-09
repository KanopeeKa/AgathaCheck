import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_timeline_segment.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_timeline/pet_timeline_entry_tile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('PetTimelineEntryTile care milestone', () {
    testWidgets('renders milestone title and body without edit actions', (
      tester,
    ) async {
      const segment = PetTimelineSegment(
        kind: 'care_milestone',
        id: 'ms-1',
        startDate: '2025-09-01',
        milestoneType: 'weight_monitoring_established',
        includesFirstCare: true,
      );

      await tester.pumpWidget(
        _wrap(
          PetTimelineEntryTile(
            segment: segment,
            petId: 'pet-1',
            petName: 'Max',
          ),
        ),
      );

      final l = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l.careProgressionMilestoneTitle), findsOneWidget);
      expect(
        find.text(l.careProgressionFirstCareCombinedBody('Max')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('timeline_edit_ms-1')), findsNothing);
      expect(find.byKey(const Key('timeline_delete_ms-1')), findsNothing);
    });
  });
}
