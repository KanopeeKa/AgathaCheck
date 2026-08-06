import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet_profile_app/features/organization/presentation/widgets/org_roles_permissions/staged_permissions_controller.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_roles_permissions/tri_state_permission_toggle.dart';

void main() {
  group('TriStatePermissionToggle', () {
    testWidgets('renders tristate switch and pending indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TriStatePermissionToggle(
              value: TriState.indeterminate,
              showPending: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsOneWidget);
      expect(
        find.byKey(const Key('org_permission_pending_indicator')),
        findsOneWidget,
      );
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.tristate, isTrue);
      expect(checkbox.value, isNull);
    });

    testWidgets('tapping indeterminate switch calls onChanged(true)', (
      tester,
    ) async {
      bool? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TriStatePermissionToggle(
              value: TriState.indeterminate,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(changed, isTrue);
    });

    testWidgets('tapping off switch calls onChanged(true)', (tester) async {
      bool? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TriStatePermissionToggle(
              value: TriState.off,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(changed, isTrue);
    });
  });
}
