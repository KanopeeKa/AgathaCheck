import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/widgets/agatha_message_card.dart';
import 'package:pet_profile_app/features/care_intelligence/presentation/widgets/suggestion_why_button.dart';

void main() {
  testWidgets('round why control uses Agatha action theme when themed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AgathaMessageCard(
            themeSuggestionActions: true,
            child: SuggestionWhyButton(tooltip: 'Why?', onPressed: () {}),
          ),
        ),
      ),
    );

    expect(find.text('?'), findsOneWidget);
    expect(find.text('Why?'), findsNothing);

    final buttonContext = tester.element(find.byType(OutlinedButton));
    final borderColor = Theme.of(
      buttonContext,
    ).outlinedButtonTheme.style?.side?.resolve({})?.color;
    expect(borderColor, AppColorTokens.agathaTealAction);
  });
}
