import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agathacheck/features/auth/presentation/widgets/profile_header_card.dart';

void main() {
  testWidgets('ProfileHeaderCard displays user info', (WidgetTester tester) async {
    final user = {
      'displayName': 'Jane Doe',
      'email': 'jane@example.com',
      'category': 'pet_guardian',
      'bio': 'Loves pets',
      'photoUrl': '',
      'initials': 'JD',
    };
    await tester.pumpWidget(MaterialApp(
      home: ProfileHeaderCard(
        user: user,
        theme: ThemeData(),
        l10n: TestL10n(),
        onEdit: () {},
        resolvePhotoUrl: (url) => url,
      ),
    ));
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('jane@example.com'), findsOneWidget);
    expect(find.text('Loves pets'), findsOneWidget);
  });
}

class TestL10n {
  String get professionalMultiPet => 'Professional Multi Pet';
  String get petGuardian => 'Pet Guardian';
  String get myDetails => 'My Details';
  String get detailsVisibleToShared => 'Details visible to shared users';
  String categoryLabel(String label) => label;
}
