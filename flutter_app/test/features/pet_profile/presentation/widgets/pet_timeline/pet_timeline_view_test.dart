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

  group('PetTimelineEventRow layout', () {
    testWidgets('connector spans from below the node to the row bottom', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          PetTimelineEventRow(
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
      );

      final rowRect = tester.getRect(find.byType(PetTimelineEventRow));
      final connectorRect = tester.getRect(
        find.byKey(const Key('pet_timeline_node_connector')),
      );

      expect(
        connectorRect.top,
        rowRect.top + PetTimelineNode.nodeSize,
        reason: 'connector starts just below the spine node',
      );
      expect(
        connectorRect.bottom,
        rowRect.bottom,
        reason: 'connector reaches the bottom of the row',
      );
      expect(
        connectorRect.center.dx,
        closeTo(rowRect.left + PetTimelineNode.spineWidth / 2, 0.5),
        reason: 'connector is centred under the spine node',
      );
    });

    testWidgets('avoids intrinsic measurement for scroll performance', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          PetTimelineEventRow(
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
      );

      expect(find.byType(IntrinsicHeight), findsNothing);
    });
  });
}
