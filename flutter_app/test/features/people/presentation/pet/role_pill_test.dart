import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/widgets/role_pill.dart';

import '../people_test_harness.dart';

void main() {
  testWidgets('RolePill wraps at 200% text scale', (tester) async {
    await tester.pumpWidget(
      peopleTestApp(
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const RolePill(
            label: 'Primary vet',
            leadingIcon: Icons.star_rounded,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RolePill), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
