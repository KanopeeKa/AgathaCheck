import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../providers/org_provider_deps.dart';
import '../../widgets/adoption_journey/adoption_journey_milestone_checklist.dart';
import '../../widgets/org_shell_app_bar_title.dart';
import '../../widgets/org_shell_scaffold.dart';

class AdoptionJourneyDetailScreen extends ConsumerWidget {
  const AdoptionJourneyDetailScreen({
    super.key,
    required this.orgId,
    required this.placementId,
  });

  final String orgId;
  final String placementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(orgTokenProvider);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return OrgShellScaffold(
      title: l.adoptionJourneyTitle,
      orgId: orgId,
      navVariant: OrgNavTitleVariant.withOrgLogo,
      child: FutureBuilder<Map<String, dynamic>>(
        future: token == null
            ? Future.error(StateError('Not authenticated'))
            : ref
                  .read(organizationRepositoryProvider)
                  .getAdoptionJourney(orgId, placementId, token),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final journey =
              snapshot.data?['adoption_journey'] as Map<String, dynamic>? ?? {};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l.adoptionJourneyStatusLabel,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                journey['status']?.toString() ?? l.adoptionJourneyStatusUnknown,
              ),
              const SizedBox(height: 16),
              Text(
                l.adoptionJourneyConditionsLabel,
                style: theme.textTheme.titleSmall,
              ),
              Text(journey['adoption_conditions']?.toString() ?? ''),
              const SizedBox(height: 24),
              AdoptionJourneyMilestoneChecklist(
                orgId: orgId,
                placementId: placementId,
              ),
            ],
          );
        },
      ),
    );
  }
}
