import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_timeline_segment.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_timeline/pet_timeline_event_row.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_timeline/pet_timeline_year_divider.dart';

void main() {
  group('PetTimelineYearDivider', () {
    testWidgets('renders subtle year label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PetTimelineYearDivider(year: '2025')),
        ),
      );

      expect(find.text('2025'), findsOneWidget);
      expect(find.byKey(const Key('pet_timeline_year_2025')), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });

  group('PetTimelineNode', () {
    testWidgets('shows connector when not last', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
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
        ),
      );

      expect(find.byType(PetTimelineEventRow), findsOneWidget);
    });
  });
}
