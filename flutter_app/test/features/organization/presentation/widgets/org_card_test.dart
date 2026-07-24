import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_screen_theme.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_card.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  const organization = Organization(
    id: 'org-1',
    name: 'Rescue Hearts',
    type: OrganizationType.charity,
    memberCount: 3,
    petCount: 12,
  );

  testWidgets('org card uses surface fill without elevation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: orgThemed(
            child: Scaffold(body: OrgCard(organization: organization)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, orgListCardColor());
    expect(card.elevation, 0);
    expect((card.shape as RoundedRectangleBorder).side, BorderSide.none);
  });
}
