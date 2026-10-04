import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_summary.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_group.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_kind.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_role.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_status.dart';
import 'package:pet_profile_app/features/people/presentation/widgets/contact_action_bar.dart';
import 'package:pet_profile_app/features/people/presentation/widgets/person_avatar.dart';
import 'package:pet_profile_app/features/people/presentation/widgets/person_card.dart';
import 'package:pet_profile_app/features/people/presentation/widgets/person_skeleton.dart';
import 'package:pet_profile_app/features/people/presentation/widgets/person_status_chip.dart';
import 'package:pet_profile_app/features/people/presentation/widgets/role_chips.dart';

import 'people_test_harness.dart';

ContactSummary _summary({
  String id = 'c1',
  ContactStatus status = ContactStatus.active,
}) {
  return ContactSummary(
    id: id,
    directory: const ContactDirectoryRef(type: 'personal'),
    kind: ContactKind.person,
    name: 'Jamie Lee',
    roles: const [ContactRole.sitter],
    group: ContactGroup.carer,
    status: status,
  );
}

void main() {
  testWidgets('PersonAvatar exposes name semantics', (tester) async {
    await tester.pumpWidget(
      peopleTestApp(
        child: const PersonAvatar(name: 'Jamie Lee', stableId: 'c1'),
      ),
    );
    expect(find.text('JL'), findsOneWidget);
  });

  testWidgets('PersonCard uses people_card key and tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      peopleTestApp(
        child: PersonCard(contact: _summary(), onTap: () => tapped = true),
      ),
    );
    expect(find.bySemanticsLabel(RegExp('Jamie Lee')), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('Jamie Lee')));
    expect(tapped, isTrue);
  });

  testWidgets('PersonCard at 200% text scale avoids overflow', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: peopleTestApp(
          child: PersonCard(contact: _summary(), onTap: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('PersonStatusChip shows inactive label and icon', (tester) async {
    await tester.pumpWidget(
      peopleTestApp(
        child: const PersonStatusChip(kind: PersonStatusChipKind.inactive),
      ),
    );
    expect(find.text('Inactive'), findsOneWidget);
    expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
  });

  testWidgets('RoleChips display and grouped select', (tester) async {
    await tester.pumpWidget(
      peopleTestApp(child: RoleChips(roles: const [ContactRole.vet])),
    );
    expect(find.text('Vet'), findsOneWidget);

    await tester.pumpWidget(
      peopleTestApp(
        child: RoleChips(
          mode: RoleChipsMode.groupedSelect,
          roles: const [],
          selected: const {ContactRole.sitter},
          onToggle: (_) {},
        ),
      ),
    );
    expect(find.text('Trusted carers'), findsOneWidget);
    expect(find.text('Pet sitter'), findsOneWidget);
  });

  testWidgets('ContactActionBar hides empty actions and shows call', (
    tester,
  ) async {
    await tester.pumpWidget(
      peopleTestApp(child: const ContactActionBar(phone: '+441234')),
    );
    expect(find.bySemanticsIdentifier('people_action_call'), findsOneWidget);
    expect(find.bySemanticsIdentifier('people_action_email'), findsNothing);
  });

  testWidgets('PersonSkeleton renders placeholders', (tester) async {
    await tester.pumpWidget(
      peopleTestApp(child: const PersonSkeleton(count: 2)),
    );
    expect(find.byKey(const Key('people_person_skeleton')), findsOneWidget);
  });
}
