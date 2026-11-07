import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/presentation/detail/widgets/person_detail_contact_rows.dart';

import '../people_test_harness.dart';

void main() {
  testWidgets('contact row exposes label and value as one semantics node', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      peopleTestApp(
        child: const PersonDetailContactRows(
          phone: '555-5678',
          email: null,
          address: null,
          website: null,
        ),
      ),
    );

    // SelectableText alone exposes an empty read-only field on web, so the
    // value must be carried by a label merged with the row's "Phone" label.
    final node = tester.getSemantics(
      find.bySemanticsIdentifier('people_detail_value_phone'),
    );
    expect(node.label, contains('Phone'));
    expect(node.label, contains('555-5678'));
    handle.dispose();
  });
}
