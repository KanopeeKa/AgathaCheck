import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../../organization/presentation/widgets/pet_foster_placement_section.dart';
import '../../../fostering_session/presentation/widgets/pet_fostering_session_summary_card.dart';
import '../../domain/entities/pet_viewer_role.dart';
import '../../domain/services/pet_detail_actions.dart';
import '../controllers/download_report_controller.dart';
import '../providers/pet_detail_viewer_context_provider.dart';
import '../providers/pet_providers.dart';
import '../widgets/pet_detail/pet_detail_profile_card.dart';
import '../widgets/pet_detail/pet_profile_section_nav.dart';
import 'widgets/chip_reminder_card.dart';
import 'widgets/neuter_reminder_card.dart';
import 'widgets/pet_events_preview_section.dart';
import 'widgets/sharing_section.dart';

class PetDetailScreen extends ConsumerStatefulWidget {
  const PetDetailScreen({super.key, required this.petId});

  final String petId;

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final petListAsync = ref.watch(allPetsIncludingOrgProvider);
    final l = AppLocalizations.of(context)!;

    return petListAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(child: Text(l.errorWithMessage(error.toString()))),
      ),
      data: (pets) {
        final pet = pets.where((p) => p.id == widget.petId).firstOrNull;
        if (pet == null) {
          return Scaffold(body: Center(child: Text(l.petNotFound)));
        }

        final theme = Theme.of(context);
        final isOrgPet = pet.organizationId != null;
        final experience = AppExperience.guardian;
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

        final contextualActions = <Widget>[
          if (showSharing)
            IconButton(
              key: const Key('pet_detail_sharing_action'),
              tooltip: l.sharingSection,
              icon: const Icon(Icons.people_outline),
              onPressed: () =>
                  showSharingSheet(context, ref, petId: widget.petId, pet: pet),
            ),
          if (showExport)
            IconButton(
              key: const Key('pet_detail_export_report_action'),
              tooltip: l.downloadPetReport,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () =>
                  DownloadReportController(ref).onDownloadReport(context, pet),
            ),
        ];

        Widget body = ExperienceShellScaffold(
          experience: experience,
          currentLocation: GoRouterState.of(context).uri.path,
          screenTitle: pet.name,
          backPath: '/g/home',
          contextualActions: contextualActions,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PetDetailProfileCard(
                  pet: pet,
                  viewerContext: viewerContext,
                ),
              ),
              if (pet.neuteredDate == null &&
                  !pet.neuterDismissed &&
                  !AppConstants.speciesWithoutNeutering.contains(pet.species))
                SliverToBoxAdapter(child: NeuterReminderCard(pet: pet)),
              if (pet.chipId.isEmpty && !pet.chipDismissed)
                SliverToBoxAdapter(child: ChipReminderCard(pet: pet)),
              if (viewerContext.role == PetViewerRole.fosterCarer && pet.isFoster)
                SliverToBoxAdapter(
                  child: PetFosteringSessionSummaryCard(petId: widget.petId),
                ),
              if (viewerContext.can(PetDetailAction.fosterPlacement))
                SliverToBoxAdapter(
                  child: PetFosterPlacementSection(
                    orgId: pet.organizationId!,
                    petId: widget.petId,
                    petName: pet.name,
                  ),
                ),
              SliverToBoxAdapter(
                child: PetProfileSectionNav(petId: widget.petId),
              ),
              SliverToBoxAdapter(
                child: PetEventsPreviewSection(petId: widget.petId, pet: pet),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
