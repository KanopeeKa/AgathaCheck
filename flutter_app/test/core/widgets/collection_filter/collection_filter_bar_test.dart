import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/widgets/collection_filter/collection_filter.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  const dimensions = [
    CollectionFilterDimension(
      id: 'type',
      label: 'Type',
      choices: [
        CollectionFilterChoice(id: 'all', label: 'All', isDefault: true),
        CollectionFilterChoice(id: 'med', label: 'Medication'),
      ],
    ),
    CollectionFilterDimension(
      id: 'status',
      label: 'Status',
      choices: [CollectionFilterChoice(id: 'open', label: 'Open')],
    ),
  ];

  Widget wrap(Widget child, {double width = 800}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets('toolbar shows primary dimension triggers on wide layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        CollectionFilterBar(
          dimensions: dimensions,
          selections: const {},
          onSelectionsChanged: (_) {},
          primaryDimensionIds: const ['type'],
          moreDimensionIds: const ['status'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('filter_dimension_trigger_type')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('collection_filter_more_trigger')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('collection_filter_mobile_trigger')),
      findsNothing,
    );
  });

  testWidgets('mobile layout uses filter sheet trigger', (tester) async {
    await tester.pumpWidget(
      wrap(
        CollectionFilterBar(
          dimensions: dimensions,
          selections: const {},
          onSelectionsChanged: (_) {},
          primaryDimensionIds: const ['type'],
          moreDimensionIds: const ['status'],
        ),
        width: 400,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('collection_filter_mobile_trigger')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('filter_dimension_trigger_type')),
      findsNothing,
    );
  });

  testWidgets('active chips render for non-default selections', (tester) async {
    await tester.pumpWidget(
      wrap(
        CollectionFilterBar(
          dimensions: dimensions,
          selections: const {
            'type': {'med'},
          },
          onSelectionsChanged: (_) {},
          primaryDimensionIds: const ['type'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('active_filter_type_med')), findsOneWidget);
  });
}
