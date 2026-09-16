import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/features/sharing/data/datasources/sharing_remote_datasource.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/pet_access.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/share_link.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/share_preview.dart';
import 'package:pet_profile_app/features/sharing/domain/repositories/sharing_repository.dart';
import 'package:pet_profile_app/features/sharing/presentation/providers/sharing_providers.dart';
import 'package:pet_profile_app/features/sharing/presentation/screens/shared_pet_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class FakeSharingRepository implements SharingRepository {
  FakeSharingRepository({this.preview, this.throwExpired = false});

  final SharePreview? preview;
  final bool throwExpired;

  @override
  Future<SharePreview> getSharePreview(String code) async {
    if (throwExpired) throw SharePreviewExpiredException();
    return preview ??
        const SharePreview(
          pet: {'name': 'Buddy', 'species': 'Dog'},
          owner: null,
        );
  }

  @override
  Future<String> createShare(
    String petId,
    String token, {
    String accessRole = 'carer',
  }) async =>
      'code';

  @override
  Future<String> acceptShare(String code, String token) async => 'pet-1';

  @override
  Future<List<PetAccess>> getAccess(String petId, String token) async => [];

  @override
  Future<void> updateRole(
    String petId,
    String userId,
    String role,
    String token,
  ) async {}

  @override
  Future<void> removeAccess(String petId, String userId, String token) async {}

  @override
  Future<List<ShareLink>> getShareLinks(String petId, String token) async => [];

  @override
  Future<void> deleteShareLink(String linkId, String token) async {}

  @override
  Future<void> stopFollowing(String petId, String token) async {}

  @override
  Future<void> hideSharedPet(
    String petId,
    String token, {
    required bool hidden,
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> getHiddenSharedPets(String token) async =>
      [];

  @override
  Future<void> transferOwnership(
    String petId, {
    required String recipientEmail,
    required String confirmationName,
    required String token,
  }) async {}
}

Widget buildTestApp(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('SharedPetScreen renders pet profile from repository preview', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        const SharedPetScreen(shareCode: 'abc'),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          sharingRepositoryProvider.overrideWithValue(FakeSharingRepository()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Buddy'), findsWidgets);
  });

  testWidgets('SharedPetScreen shows error on expired preview', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        const SharedPetScreen(shareCode: 'expired'),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          sharingRepositoryProvider.overrideWithValue(
            FakeSharingRepository(throwExpired: true),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Pet not found'), findsOneWidget);
  });
}
