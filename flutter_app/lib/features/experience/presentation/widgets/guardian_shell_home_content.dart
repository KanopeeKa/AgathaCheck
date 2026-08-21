import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../screens/guardian/guardian_dashboard_helpers.dart';
import '../screens/guardian/add_event_type_picker_sheet.dart';
import '../screens/guardian/guardian_my_pets_section.dart';
import '../screens/guardian/guardian_my_vets_section.dart';
import '../screens/guardian/guardian_upcoming_events_section.dart';
import 'guardian_today_orientation.dart';
import 'guardian_operations_desk_layout.dart';

/// Guardian dashboard body: My Pets, Upcoming Pet Events, My Vets (phase 2.1).
class GuardianShellHomeContent extends ConsumerWidget {
  const GuardianShellHomeContent({
    super.key,
    required this.allPets,
    required this.controller,
  });

  final List<Pet> allPets;
  final PetListController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shellPets = controller.guardianShellPets(allPets);
    final entriesAsync = ref.watch(healthEntriesNotifierProvider);
    final careSummary = entriesAsync.valueOrNull == null
        ? null
        : GuardianTodayCareSummary.forPets(
            entries: entriesAsync.valueOrNull!,
            pets: shellPets,
          );
    final todayState = guardianTodayScreenState(
      hasPets: shellPets.any((pet) => !pet.passedAway),
      hasCareData: entriesAsync.hasValue,
      isLoading: entriesAsync.isLoading,
      hasError: entriesAsync.hasError,
      hasAttention: careSummary?.hasAttention ?? false,
    );
    final previewPets = careSummary == null
        ? shellPets
              .where((pet) => !pet.passedAway)
              .take(4)
              .toList(growable: false)
        : guardianTodayPreviewPets(allPets, controller, careSummary);
    final baseTheme = Theme.of(context);
    final deskTheme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: AppColorTokens.guardianCarePrimary,
        onPrimary: AppColorTokens.inverse,
        primaryContainer: AppColorTokens.operationsPaper,
        onPrimaryContainer: AppColorTokens.guardianCareActive,
        surface: AppColorTokens.operationsSurface,
        onSurface: AppColorTokens.operationsInk,
        surfaceContainerHighest: AppColorTokens.operationsPaper,
        outlineVariant: AppColorTokens.operationsOlive.withValues(alpha: 0.18),
      ),
      scaffoldBackgroundColor: AppColorTokens.operationsDeskCanvas,
      cardTheme: baseTheme.cardTheme.copyWith(
        color: AppColorTokens.operationsSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorTokens.guardianCarePrimary,
          minimumSize: const Size(48, 48),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Theme(
          data: deskTheme,
          child: ColoredBox(
            color: AppColorTokens.operationsDeskCanvas,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: GuardianOperationsDeskLayout(
                useWideLayout:
                    constraints.maxWidth >=
                    GuardianOperationsDeskLayout.wideBreakpoint,
                todayHeader: GuardianTodayOrientation(
                  state: todayState,
                  summary: careSummary,
                  onRetry: () => ref
                      .read(healthEntriesNotifierProvider.notifier)
                      .refresh(),
                ),
                petsSection: GuardianMyPetsSection(
                  allPets: allPets,
                  controller: controller,
                  previewPets: previewPets,
                  careSummary: careSummary,
                ),
                eventsSection: GuardianUpcomingEventsSection(
                  pets: shellPets,
                  onAddEvent: () =>
                      showAddEventTypePickerSheet(context, pets: shellPets),
                ),
                vetsSection: const GuardianMyVetsSection(),
              ),
            ),
          ),
        );
      },
    );
  }
}
