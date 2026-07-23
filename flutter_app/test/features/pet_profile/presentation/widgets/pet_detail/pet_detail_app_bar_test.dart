import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_detail/pet_detail_app_bar.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/fakes.dart';

Widget _wrap({required int unreadCount}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      unreadNotificationCountProvider.overrideWithValue(unreadCount),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CustomScrollView(slivers: [PetDetailAppBar(petName: 'Rex')]),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the pet name and no badge when there are no unread '
      'notifications', (tester) async {
    await tester.pumpWidget(_wrap(unreadCount: 0));
    await tester.pumpAndSettle();

    expect(find.text('Rex'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    // No badge counter rendered when the unread count is zero.
    expect(find.text('1'), findsNothing);
  });

  testWidgets('shows the unread notification badge count', (tester) async {
    await tester.pumpWidget(_wrap(unreadCount: 3));
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('caps the unread badge at 99+', (tester) async {
    await tester.pumpWidget(_wrap(unreadCount: 150));
    await tester.pumpAndSettle();

    expect(find.text('99+'), findsOneWidget);
  });
}
