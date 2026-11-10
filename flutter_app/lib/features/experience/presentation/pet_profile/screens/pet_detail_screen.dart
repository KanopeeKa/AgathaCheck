import 'package:flutter/material.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pet_profile_app/core/widgets/async_state/async_state.dart';
import 'package:pet_profile_app/core/widgets/screen_overflow_actions.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/core/experience/app_experience.dart';
import 'package:pet_profile_app/core/router/experience_shell_scaffold.dart';
import 'package:pet_profile_app/features/care_intelligence/care_intelligence.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import '../controllers/download_report_controller.dart';
import '../widgets/pet_detail/pet_detail_scroll_body.dart';

class PetDetailScreen extends ConsumerStatefulWidget {
  const PetDetailScreen({super.key, required this.petId});

  final String petId;

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(petCareRecommendationsProvider(widget.petId));
      ref.invalidate(petCareSafeguardsProvider(widget.petId));
      ref.invalidate(petPendingCareMomentsProvider(widget.petId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final petListAsync = ref.watch(petListProvider);
    final l = AppLocalizations.of(context)!;
    final experience = AppExperience.petCare;
    final location = GoRouterState.of(context).uri.path;

    Widget routeShell({
      required Widget child,
      String? screenTitle,
      List<Widget> contextualActions = const [],
    }) {
      return ExperienceShellScaffold(
        experience: experience,
        currentLocation: location,
        screenTitle: screenTitle ?? l.petDetails,
        contextualActions: contextualActions,
        child: child,
      );
    }

    return petListAsync.when(
      loading: () => routeShell(
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => routeShell(
        child: AsyncErrorState(
          title: l.loadErrorYourPets,
          onRetry: () => ref.invalidate(petListProvider),
          retryKey: const Key('pet_detail_load_retry'),
        ),
      ),
      data: (pets) {
        final pet = pets.where((p) => p.id == widget.petId).firstOrNull;
        if (pet == null) {
          return routeShell(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AsyncErrorState(title: l.petNotFound),
                TextButton(
                  key: const Key('pet_detail_back_to_pets'),
                  onPressed: () => context.go('/pc/pets'),
                  child: Text(l.backToPets),
                ),
              ],
            ),
          );
        }

        final theme = Theme.of(context);
        final isOrgPet = pet.organizationId != null;
        final useOrgChrome =
            isOrgPet && experience == AppExperience.organization;
        final viewerContext = ref.watch(
          petDetailViewerContextProvider(widget.petId),
        );

        final showSharing =
            viewerContext.can(PetDetailAction.manageSharing) ||
            pet.isShared ||
            pet.isFoster;
        final showExport = viewerContext.can(PetDetailAction.downloadReport);

        final overflowActions = <ScreenOverflowAction>[
          if (viewerContext.can(PetDetailAction.planAbsence))
            ScreenOverflowAction(
              key: const Key('pet_detail_plan_absence_action'),
              menuItemKey: const Key('pet_detail_plan_absence_menu_item'),
              semanticsIdentifier: 'pet_detail_plan_absence_menu_item',
              label: l.careContextPlanAnAbsence,
              icon: Icons.flight_takeoff_outlined,
              onPressed: () =>
                  context.push('/pc/away/new?petId=${widget.petId}'),
            ),
          if (showSharing)
            ScreenOverflowAction(
              key: const Key('pet_detail_sharing_action'),
              menuItemKey: const Key('pet_detail_sharing_menu_item'),
              semanticsIdentifier: 'pet_detail_sharing_menu_item',
              label: l.sharingSection,
              icon: Icons.people_outline,
              onPressed: () => context.push('/pet/${widget.petId}/share'),
            ),
          if (showExport)
            ScreenOverflowAction(
              key: const Key('pet_detail_export_report_action'),
              menuItemKey: const Key('pet_detail_export_report_menu_item'),
              semanticsIdentifier: 'pet_detail_export_report_menu_item',
              label: l.downloadPetReport,
              icon: Icons.picture_as_pdf_outlined,
              onPressed: () =>
                  DownloadReportController(ref).onDownloadReport(context, pet),
            ),
        ];

        final contextualActions = <Widget>[
          ScreenOverflowActions(
            menuKey: const Key('pet_detail_overflow_menu'),
            menuSemanticsIdentifier: 'pet_detail_overflow_menu',
            tooltip: l.moreActions,
            actions: overflowActions,
          ),
        ];

        Widget body = ExperienceShellScaffold(
          experience: experience,
          currentLocation: GoRouterState.of(context).uri.path,
          screenTitle: pet.name,
          contextualActions: contextualActions,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: PetListStaleBanner()),
              SliverToBoxAdapter(
                child: PetDetailScrollBody(
                  pet: pet,
                  viewerContext: viewerContext,
                ),
              ),
            ],
          ),
        );

        if (useOrgChrome) {
          body = Theme(
            data: theme.copyWith(
              cardTheme: theme.cardTheme.copyWith(
                color: theme.colorScheme.surface,
              ),
            ),
            child: body,
          );
        }

        return body;
      },
    );
  }
}
