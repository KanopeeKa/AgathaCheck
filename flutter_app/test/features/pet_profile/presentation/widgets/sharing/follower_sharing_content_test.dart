import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/sharing/follower_sharing_content.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('FollowerSharingContent shows stop following button', (
    tester,
  ) async {
    const pet = Pet(id: 'p1', name: 'Buddy', species: 'dog', breed: 'Lab');

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FollowerSharingContent(petId: 'p1', pet: pet),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person_remove), findsOneWidget);
    expect(find.textContaining('Buddy'), findsWidgets);
  });
}
