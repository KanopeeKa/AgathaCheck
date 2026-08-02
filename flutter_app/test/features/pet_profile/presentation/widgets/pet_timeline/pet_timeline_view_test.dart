import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_timeline_segment.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_timeline/pet_timeline_event_row.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_timeline/pet_timeline_year_divider.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('PetTimelineYearDivider', () {
    testWidgets('renders subtle year label', (tester) async {
      await tester.pumpWidget(
        _wrap(const PetTimelineYearDivider(year: '2025')),
      );

      expect(find.text('2025'), findsOneWidget);
      expect(find.byKey(const Key('pet_timeline_year_2025')), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });

  group('PetTimelineNode', () {
    testWidgets('shows connector when not last', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            height: 120,
            child: PetTimelineEventRow(
              segment: const PetTimelineSegment(
                kind: 'manual',
                id: 'm1',
                startDate: '2025-01-01',
                title: 'Test',
              ),
              showConnectorBelow: true,
              child: const SizedBox(height: 80, child: Card(child: Text('x'))),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('pet_timeline_node_connector')),
        findsOneWidget,
      );
    });

    testWidgets('hides connector on last row', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            height: 120,
            child: PetTimelineEventRow(
              segment: const PetTimelineSegment(
                kind: 'manual',
                id: 'm1',
                startDate: '2025-01-01',
                title: 'Test',
              ),
              showConnectorBelow: false,
              child: const SizedBox(height: 80, child: Card(child: Text('x'))),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('pet_timeline_node_connector')),
        findsNothing,
      );
    });
  });
}
