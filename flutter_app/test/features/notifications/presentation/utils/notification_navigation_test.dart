import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/notifications/domain/entities/app_notification.dart';
import 'package:pet_profile_app/features/notifications/presentation/utils/notification_navigation.dart';

AppNotification _notification({
  String? petId,
  String? healthEntryId,
  String? organizationId,
}) {
  return AppNotification(
    id: 'n-1',
    userId: 'user-1',
    petId: petId,
    healthEntryId: healthEntryId,
    organizationId: organizationId,
    title: 'Test',
    message: 'Message',
    type: NotificationType.overdue,
    isRead: false,
    createdAt: DateTime.now(),
  );
}

void main() {
  testWidgets('navigates to view entry when health entry id is present', (
    tester,
  ) async {
    late Uri uri;

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/pc/home',
          routes: [
            GoRoute(
              path: '/pc/home',
              builder: (context, state) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => navigateFromNotification(
                    context,
                    _notification(petId: 'pet-1', healthEntryId: 'entry-1'),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
            GoRoute(
              path: '/pet/:petId/events/:entryId',
              builder: (context, state) {
                uri = state.uri;
                return const Scaffold(body: Text('View entry'));
              },
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(uri.path, '/pet/pet-1/events/entry-1');
    expect(uri.queryParameters['returnTo'], '/pc/home');
    expect(find.text('View entry'), findsOneWidget);
  });

  testWidgets(
    'uses notifications route as returnTo from notifications screen',
    (tester) async {
      late Uri uri;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/notifications',
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () => navigateFromNotification(
                      context,
                      _notification(petId: 'pet-1', healthEntryId: 'entry-1'),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
              GoRoute(
                path: '/pet/:petId/events/:entryId',
                builder: (context, state) {
                  uri = state.uri;
                  return const Scaffold(body: Text('View entry'));
                },
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(uri.queryParameters['returnTo'], '/notifications');
    },
  );

  testWidgets(
    'navigates to view entry when health entry id is present (legacy path)',
    (tester) async {
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
                      _notification(petId: 'pet-1', healthEntryId: 'entry-1'),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
              GoRoute(
                path: '/pet/:petId/events/:entryId',
                builder: (context, state) {
                  location = state.uri.path;
                  return const Scaffold(body: Text('View entry'));
                },
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(location, '/pet/pet-1/events/entry-1');
      expect(find.text('View entry'), findsOneWidget);
    },
  );

  testWidgets('falls back to pet profile when health entry id is missing', (
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
                    _notification(petId: 'pet-1'),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
            GoRoute(
              path: '/pet/:petId',
              builder: (context, state) {
                location = state.uri.path;
                return const Scaffold(body: Text('Pet profile'));
              },
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(location, '/pet/pet-1');
    expect(find.text('Pet profile'), findsOneWidget);
  });

  testWidgets('navigates to organisation detail when no pet id', (
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
                    _notification(organizationId: 'org-1'),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
            GoRoute(
              path: '/o/orgs/:orgId',
              builder: (context, state) {
                location = state.uri.path;
                return const Scaffold(body: Text('Org detail'));
              },
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(location, '/o/orgs/org-1');
    expect(find.text('Org detail'), findsOneWidget);
  });
}
