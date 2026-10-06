import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/pet_profile/widgets/pet_list/pet_list_status_views.dart';

void main() {
  testWidgets('PetListErrorBody shows retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PetListErrorBody(
            message: 'Load failed',
            retryLabel: 'Retry',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Load failed'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('PetListNoPetsEmptyBody shows headline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PetListNoPetsEmptyBody(
            headline: 'No pets yet',
            subtitle: 'Add one',
            showSubtitle: true,
          ),
        ),
      ),
    );

    expect(find.text('No pets yet'), findsOneWidget);
    expect(find.text('Add one'), findsOneWidget);
  });

  testWidgets('PetListFilterEmptyBody clear filter', (tester) async {
    var cleared = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PetListFilterEmptyBody(
            message: 'No match',
            showClearFilter: true,
            clearFilterLabel: 'Show all',
            onClearFilter: () => cleared = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show all'));
    expect(cleared, isTrue);
  });
}
