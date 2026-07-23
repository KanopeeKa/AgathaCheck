import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/presentation/providers/experience_providers.dart';
import '../../../organization/presentation/widgets/pet_foster_placement_section.dart';
import '../../domain/services/pet_detail_actions.dart';
import '../providers/pet_detail_viewer_context_provider.dart';
import '../providers/pet_providers.dart';
import '../widgets/pet_detail/pet_detail_app_bar.dart';
import '../widgets/pet_detail/pet_detail_profile_card.dart';
import 'widgets/chip_reminder_card.dart';
import 'widgets/download_report_section.dart';
import 'widgets/other_events_section.dart';
import 'widgets/health_events_section.dart';
import 'widgets/health_issues_section.dart';
import 'widgets/neuter_reminder_card.dart';
import 'widgets/sharing_section.dart';
import 'widgets/weight_tracking_section.dart';

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
        appBar: AppBar(title: AppLogoTitle(title: l.petDetails)),
        body: Center(child: Text(l.errorWithMessage(error.toString()))),
      ),
      data: (pets) {
        final pet = pets.where((p) => p.id == widget.petId).firstOrNull;
        if (pet == null) {
          return Scaffold(
            appBar: AppBar(title: AppLogoTitle(title: l.petDetails)),
            body: Center(child: Text(l.petNotFound)),
          );
        }

        final theme = Theme.of(context);
        final isOrgPet = pet.organizationId != null;
        final experience = ref.watch(resolvedExperienceProvider);
        final useOrgChrome =
            isOrgPet && experience == AppExperience.organization;
        final viewerContext = ref.watch(
          petDetailViewerContextProvider(widget.petId),
        );
        final backPath = ref.watch(experienceHomePathProvider);

        Widget body = Scaffold(
          body: CustomScrollView(
            slivers: [
              PetDetailAppBar(petName: pet.name, backPath: backPath),
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
              if (viewerContext.can(PetDetailAction.fosterPlacement))
                SliverToBoxAdapter(
                  child: PetFosterPlacementSection(
                    orgId: pet.organizationId!,
                    petId: widget.petId,
                    petName: pet.name,
                  ),
                ),
              SliverToBoxAdapter(
                child: WeightTrackingSection(petId: widget.petId),
              ),
              SliverToBoxAdapter(
                child: HealthIssuesSection(petId: widget.petId, pet: pet),
              ),
              SliverToBoxAdapter(
                child: HealthEventsSection(petId: widget.petId, pet: pet),
              ),
              SliverToBoxAdapter(
                child: OtherEventsSection(petId: widget.petId, pet: pet),
              ),
              if (viewerContext.can(PetDetailAction.manageSharing) ||
                  pet.isShared ||
                  pet.isFoster)
                SliverToBoxAdapter(
                  child: SharingSection(petId: widget.petId, pet: pet),
                ),
              if (viewerContext.can(PetDetailAction.downloadReport))
                SliverToBoxAdapter(child: DownloadReportSection(pet: pet)),
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
