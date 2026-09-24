import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/router/shell_return_navigation.dart';

void main() {
  group('parseShellReturnTo', () {
    test('accepts encoded in-app paths', () {
      expect(parseShellReturnTo(Uri.encodeComponent('/g/pets')), '/g/pets');
    });

    test('rejects external URLs', () {
      expect(parseShellReturnTo('https://evil.test'), isNull);
    });

    test('rejects protocol-relative paths', () {
      expect(parseShellReturnTo('//evil.test'), isNull);
    });

    test('rejects empty and whitespace', () {
      expect(parseShellReturnTo(null), isNull);
      expect(parseShellReturnTo(''), isNull);
      expect(parseShellReturnTo('   '), isNull);
    });
  });

  group('petDetailLocation', () {
    test('omits query when returnTo absent', () {
      expect(petDetailLocation('abc'), '/pet/abc');
    });

    test('encodes returnTo query', () {
      expect(
        petDetailLocation('abc', returnTo: '/g/pets'),
        '/pet/abc?returnTo=%2Fg%2Fpets',
      );
    });
  });

  group('vetDetailLocation', () {
    test('omits query when returnTo absent', () {
      expect(vetDetailLocation('vet-1'), '/pc/vets/vet-1');
    });

    test('encodes returnTo query', () {
      expect(
        vetDetailLocation('vet-1', returnTo: '/pc/home'),
        '/pc/vets/vet-1?returnTo=%2Fpc%2Fhome',
      );
    });
  });

  group('petEventViewLocation', () {
    test('omits query when returnTo absent', () {
      expect(
        petEventViewLocation('pet-1', 'entry-1'),
        '/pet/pet-1/events/entry-1',
      );
    });

    test('encodes returnTo query', () {
      expect(
        petEventViewLocation('pet-1', 'entry-1', returnTo: '/pc/away/abs-1'),
        '/pet/pet-1/events/entry-1?returnTo=%2Fpc%2Faway%2Fabs-1',
      );
    });
  });

  group('shellFallbackReturnPath', () {
    test('prefers returnTo over explicit backPath when both set', () {
      expect(
        shellFallbackReturnPath(
          explicitBackPath: '/explicit',
          returnTo: '/g/pets',
          defaultPath: '/g/home',
        ),
        '/g/pets',
      );
    });

    test('uses backPath when returnTo absent', () {
      expect(
        shellFallbackReturnPath(
          explicitBackPath: '/explicit',
          defaultPath: '/g/home',
        ),
        '/explicit',
      );
    });

    test('uses returnTo when backPath absent', () {
      expect(
        shellFallbackReturnPath(returnTo: '/g/pets', defaultPath: '/g/home'),
        '/g/pets',
      );
    });

    test('falls back to defaultPath', () {
      expect(shellFallbackReturnPath(defaultPath: '/g/home'), '/g/home');
    });
  });

  group('returnToPetEventView', () {
    testWidgets('pops when edit form was pushed on the stack', (tester) async {
      late GoRouter router;
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router = GoRouter(
            initialLocation:
                '/pet/pet-1/events/entry-1?returnTo=%2Fpc%2Faway%2Fabs-1',
            routes: [
              GoRoute(
                path: '/pet/:petId/events/:entryId',
                builder: (context, state) => Scaffold(
                  body: Center(
                    child: FilledButton(
                      key: const Key('open_edit'),
                      onPressed: () => GoRouter.of(
                        context,
                      ).push('/pet/pet-1/events/entry-1/edit'),
                      child: const Text('Edit'),
                    ),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, __) => Scaffold(
                      body: Center(
                        child: FilledButton(
                          key: const Key('save_edit'),
                          onPressed: () => returnToPetEventView(
                            context,
                            petId: 'pet-1',
                            entryId: 'entry-1',
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_edit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('save_edit')), findsOneWidget);

      await tester.tap(find.byKey(const Key('save_edit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('open_edit')), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        contains('returnTo=%2Fpc%2Faway%2Fabs-1'),
      );
    });
  });
}
