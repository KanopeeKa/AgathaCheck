import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/app_logo_title.dart';
import '../../providers/org_provider_deps.dart';
import '../../utils/org_screen_theme.dart';

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
    return orgThemed(
      child: Scaffold(
        appBar: AppBar(
          title: const AppLogoTitle(title: 'Adoption journey'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
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
                snapshot.data?['adoption_journey'] as Map<String, dynamic>? ??
                {};
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Status', style: theme.textTheme.titleSmall),
                Text(journey['status']?.toString() ?? 'unknown'),
                const SizedBox(height: 16),
                Text('Conditions', style: theme.textTheme.titleSmall),
                Text(journey['adoption_conditions']?.toString() ?? ''),
              ],
            );
          },
        ),
      ),
    );
  }
}
