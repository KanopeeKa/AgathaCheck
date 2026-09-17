import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/app_notification.dart';
import 'package:pet_profile_app/features/notifications/presentation/utils/notification_navigation.dart';

AppNotification _notification({
  required String wireType,
  String? petId,
  String? healthEntryId,
}) {
  return AppNotification(
    id: 'n-1',
    userId: 'user-1',
    petId: petId,
    healthEntryId: healthEntryId,
    title: 'Test',
    message: 'Message',
    type: NotificationType.general,
    wireType: wireType,
    isRead: false,
    createdAt: DateTime.now(),
  );
}

void main() {
  testWidgets('shareInviteReceived navigates to invite landing', (
    tester,
  ) async {
    late String location;

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => navigateFromNotification(
                    context,
                    _notification(
                      wireType: 'shareInviteReceived',
                      healthEntryId: 'invite01',
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
            GoRoute(
              path: '/invite/:code',
              builder: (context, state) {
                location = state.uri.path;
                return const Scaffold(body: Text('Invite landing'));
              },
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(location, '/invite/invite01');
  });

  testWidgets('shareInviteAccepted navigates to share screen', (
    tester,
  ) async {
    late String location;

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => navigateFromNotification(
                    context,
                    _notification(
                      wireType: 'shareInviteAccepted',
                      petId: 'pet-1',
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
            GoRoute(
              path: '/pet/:petId/share',
              builder: (context, state) {
                location = state.uri.path;
                return const Scaffold(body: Text('Share screen'));
              },
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(location, '/pet/pet-1/share');
  });
}
