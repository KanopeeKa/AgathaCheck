import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/subscription/presentation/widgets/paywall_feature_list_card.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('PaywallFeatureListCard lists unlimited features', (
    tester,
  ) async {
    late AppLocalizations l;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l = AppLocalizations.of(context)!;
            return Scaffold(body: PaywallFeatureListCard(theme: Theme.of(context)));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l.subscriptionPlanUnlimitedTitle), findsOneWidget);
    expect(find.text(l.subscriptionFeatureUnlimitedPets), findsOneWidget);
  });
}
