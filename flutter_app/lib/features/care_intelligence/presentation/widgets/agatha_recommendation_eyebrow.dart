import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/widgets/agatha_message_card.dart';

/// Typographic signature for Agatha-authored suggestions (no script font).
class AgathaRecommendationEyebrow extends StatelessWidget {
  const AgathaRecommendationEyebrow({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final base = AgathaMessageCardShell.titleStyle(Theme.of(context).textTheme);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: l.careSuggestionEyebrowAgatha,
            style: base.copyWith(fontStyle: FontStyle.italic),
          ),
          TextSpan(text: ' ${l.careSuggestionEyebrowRecommends}', style: base),
        ],
      ),
    );
  }
}
