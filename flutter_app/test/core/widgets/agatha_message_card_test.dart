import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/widgets/agatha_message_card.dart';

void main() {
  testWidgets('AgathaMessageCard uses message surface and border', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AgathaMessageCard(child: Text('body'))),
      ),
    );

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, AppColorTokens.agathaMessageSurface);
    final shape = card.shape as RoundedRectangleBorder;
    expect(shape.side.color, AppColorTokens.agathaMessageBorder);
  });
}
