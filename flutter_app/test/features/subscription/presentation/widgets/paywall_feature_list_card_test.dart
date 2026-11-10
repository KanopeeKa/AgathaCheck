import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/subscription/presentation/widgets/paywall_feature_list_card.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('PaywallFeatureListCard lists unlimited features', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: PaywallFeatureListCard(theme: Theme.of(context)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(PaywallFeatureListCard));
    final l = AppLocalizations.of(context)!;

    expect(find.text(l.subscriptionFeatureUnlimitedTitle), findsOneWidget);
    expect(find.text(l.subscriptionFeatureProfiles), findsOneWidget);
  });
}
