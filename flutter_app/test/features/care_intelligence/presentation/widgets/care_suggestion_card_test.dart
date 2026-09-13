import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/entities/care_recommendation.dart';
import 'package:pet_profile_app/features/care_intelligence/presentation/widgets/care_suggestion_card.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _recommendation = CareRecommendation(
  id: 'rec-1',
  petId: 'pet-1',
  careFamily: CareFamily.weightMonitoring,
  suggestionKey: 'weight.monthly',
  status: CareRecommendationStatus.pending,
  engineVersion: '1',
  knowledgeVersion: '1',
  suggestedName: 'Monthly weigh-in',
  suggestedFrequency: 'monthly',
  suggestedFrequencyInterval: 1,
  suggestedHealthEntryType: 'other',
  rationaleKey: 'weight.rhythm',
);

Widget _buildCard() {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CareSuggestionCard(
          petId: 'pet-1',
          recommendation: _recommendation,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('CareSuggestionCard uses Agatha message palette', (tester) async {
    await tester.pumpWidget(_buildCard());
    await tester.pumpAndSettle();

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, AppColorTokens.agathaMessageSurface);
    expect(find.text('Suggested by Agatha'), findsOneWidget);

    final title = tester.widget<Text>(find.text('Suggested by Agatha'));
    expect(title.style?.color, AppColorTokens.agathaTeal);
  });
}
