import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pet_profile_app/features/auth/presentation/widgets/profile_header_card.dart';
import 'package:pet_profile_app/features/auth/data/auth_service.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/l10n/app_localizations_en.dart';

void main() {
  testWidgets('ProfileHeaderCard displays user info', (
    WidgetTester tester,
  ) async {
    final user = AuthUser(
      id: 'test-id',
      email: 'jane@example.com',
      firstName: 'Jane',
      lastName: 'Doe',
      category: 'pet_guardian',
      bio: 'Loves pets',
      photoUrl: '',
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProfileHeaderCard(
            user: user,
            theme: ThemeData(),
            l10n: AppLocalizationsEn(),
            onEdit: () {},
            resolvePhotoUrl: (url) => url,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('jane@example.com'), findsOneWidget);
    expect(find.text('Loves pets'), findsOneWidget);
  });
}
