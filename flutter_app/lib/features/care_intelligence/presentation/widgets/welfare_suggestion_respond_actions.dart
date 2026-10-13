import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/care_recommendations_provider.dart';

class WelfareSuggestionRespondActions {
  const WelfareSuggestionRespondActions._();

  static Future<void> dismiss({
    required BuildContext context,
    required WidgetRef ref,
    required String petId,
    required String suggestionId,
    required ValueSetter<bool> onLoadingChanged,
  }) async {
    onLoadingChanged(true);
    try {
      await ref.read(careIntelligenceRepositoryProvider).respondWelfareSuggestion(
        petId: petId,
        suggestionId: suggestionId,
        action: 'dismiss',
      );
      ref.invalidate(petWelfareSuggestionsProvider(petId));
      ref.invalidate(petProfileWelfareSuggestionProvider(petId));
      ref.invalidate(petProfileCareSuggestionProvider(petId));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      onLoadingChanged(false);
    }
  }
}
