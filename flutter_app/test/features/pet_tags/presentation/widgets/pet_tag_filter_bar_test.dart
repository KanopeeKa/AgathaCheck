import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/pet_tags/domain/entities/pet_tag.dart';
import 'dart:async';

import 'package:pet_profile_app/features/pet_tags/presentation/providers/pet_tag_providers.dart';
import 'package:pet_profile_app/features/pet_tags/presentation/widgets/pet_tag_filter_bar.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

class _TagListErrorNotifier extends PetTagListNotifier {
  @override
  Future<List<PetTag>> build() async {
    throw Exception('tags failed');
  }
}

class _TagListLoadingNotifier extends PetTagListNotifier {
  @override
  Future<List<PetTag>> build() async {
    return Completer<List<PetTag>>().future;
  }
}

class _TagListDataNotifier extends PetTagListNotifier {
  @override
  Future<List<PetTag>> build() async => const [
    PetTag(id: 't1', name: 'Cats', petIds: ['p1']),
  ];
}

void main() {
  Widget wrap(Widget child, List<Override> overrides) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        ...overrides,
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [GoRoute(path: '/', builder: (_, __) => Scaffold(body: child))],
        ),
      ),
    );
  }

  testWidgets('shows unavailable caption and Retry when tags fail', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const PetTagFilterBar(),
        [petTagListProvider.overrideWith(() => _TagListErrorNotifier())],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tag filters unavailable'), findsOneWidget);
    expect(find.byKey(const Key('pet_tag_filters_retry')), findsOneWidget);
  });

  testWidgets('keeps filter selection visible while tags load', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PetTagFilterBar(),
        [
          petTagListProvider.overrideWith(() => _TagListLoadingNotifier()),
          petTagFilterProvider.overrideWith(() => _PrefilteredTagFilter()),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Loading tag filters…'), findsOneWidget);
  });

  testWidgets('hides bar when there are no tags', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PetTagFilterBar(),
        [petTagListProvider.overrideWith(() => _EmptyTagListNotifier())],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tag filters unavailable'), findsNothing);
    expect(find.byType(PetTagFilterBar), findsOneWidget);
  });
}

class _EmptyTagListNotifier extends PetTagListNotifier {
  @override
  Future<List<PetTag>> build() async => const [];
}

class _PrefilteredTagFilter extends PetTagFilterNotifier {
  @override
  PetTagFilterState build() =>
      const PetTagFilterState(selectedTagIds: {'t1'});
}
