import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_intelligence/data/models/care_recommendation_model.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/entities/care_recommendation.dart';
import 'package:pet_profile_app/features/care_intelligence/presentation/providers/care_recommendations_provider.dart';
import 'package:pet_profile_app/features/experience/presentation/pet_profile/widgets/pet_profile_care_suggestion_section.dart';
import 'package:pet_profile_app/features/pet_care/presentation/providers/pet_care_presentation_providers.dart';
import 'package:pet_profile_app/features/pet_care/progression/domain/entities/care_pending_moment.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

const _petId = 'pet-1';

CareRecommendation get _pendingRecommendation => const CareRecommendation(
  id: 'rec-1',
  petId: _petId,
  careFamily: CareFamily.weightMonitoring,
  suggestionKey: 'weight_monitoring_rhythm',
  status: CareRecommendationStatus.pending,
  engineVersion: '1.0.0',
  knowledgeVersion: '1.0.0',
  suggestedName: 'Weight check',
  suggestedFrequency: 'monthly',
  suggestedFrequencyInterval: 1,
  rationaleKey: 'careSuggestionWeightMonitoringWhy',
);

Pet get _pet => const Pet(
  id: _petId,
  name: 'CimDog',
  species: 'Dog',
);

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      petCareRecommendationsProvider(_petId).overrideWith(
        (ref) async => [_pendingRecommendation],
      ),
      petCareSafeguardsProvider(_petId).overrideWith((ref) async => []),
      petPendingCareMomentsProvider(_petId).overrideWith(
        (ref) async => const CarePendingMomentsResponse(
          moments: [],
          throttled: false,
        ),
      ),
      allPetsIncludingOrgProvider.overrideWith(
        (ref) async => [_pet],
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  test('parses pre-UAT care recommendations payload', () {
    const raw = '''
[{"id":"eaed83a6-06b5-4a04-8f3d-85a7b2d7e2b1","pet_id":"a7e3d591-0b0c-4d3b-b6c9-71fd1d3c7628","care_family":"weight_monitoring","suggestion_key":"weight_monitoring_rhythm","status":"pending","engine_version":"1.0.0","knowledge_version":"1.0.0","suggested_name":"Weight check","suggested_frequency":"monthly","suggested_frequency_interval":1,"rationale_key":"careSuggestionWeightMonitoringWhy","health_entry_id":null,"responded_at":null,"created_at":"2026-10-06T10:32:29.789Z","updated_at":"2026-10-06T10:32:29.789Z"}]
''';
    final list = json.decode(raw) as List<dynamic>;
    final recs = list
        .map((e) => CareRecommendationModel.fromJson(e as Map<String, dynamic>))
        .map((m) => m.toEntity())
        .toList();
    expect(recs, hasLength(1));
    expect(recs.first.isPending, isTrue);
  });

  testWidgets('shows suggestion card when recommendations are pending', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const PetProfileCareSuggestionSection(petId: _petId)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Suggested by Agatha'), findsOneWidget);
    expect(find.text('Weight check'), findsOneWidget);
  });
}
