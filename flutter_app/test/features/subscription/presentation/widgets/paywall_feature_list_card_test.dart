import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/subscription/presentation/widgets/paywall_feature_list_card.dart';

void main() {
  testWidgets('PaywallFeatureListCard lists unlimited features', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: PaywallFeatureListCard(theme: Theme.of(context)),
          ),
        ),
      ),
    );

    expect(find.text('AgathaTrack Unlimited'), findsOneWidget);
    expect(find.text('Unlimited pet profiles'), findsOneWidget);
  });
}
