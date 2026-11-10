import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/widgets/role_pill.dart';
import 'package:pet_profile_app/features/people/presentation/pet/pet_people_phone_icon_button.dart';
import 'package:pet_profile_app/features/people/presentation/pet/widgets/person_row.dart';

import '../people_test_harness.dart';

void main() {
  testWidgets('call button does not use row InkWell', (tester) async {
    var navigated = false;
    await tester.pumpWidget(
      peopleTestApp(
        child: PersonRow(
          name: 'Jamie',
          stableId: 'c1',
          phone: '555-0100',
          semanticsCallId: 'pet_people_call_c1',
          onTap: () => navigated = true,
          pills: const [RolePill(label: 'Emergency contact')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PetPeoplePhoneIconButton));
    await tester.pump();
    expect(navigated, isFalse);
  });
}
