import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/app_logo_title.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../providers/org_provider_deps.dart';
import '../../utils/org_screen_theme.dart';

class AdoptionVisitsScreen extends ConsumerWidget {
  const AdoptionVisitsScreen({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(orgTokenProvider);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return orgThemed(
      child: Scaffold(
        appBar: AppBar(title: AppLogoTitle(title: l.adoptionVisitsTitle)),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: token == null
              ? Future.value(const [])
              : ref
                    .read(organizationRepositoryProvider)
                    .getAdoptionVisits(orgId, token),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            }
            final visits = snapshot.data ?? const [];
            if (visits.isEmpty) {
              return Center(
                child: Text(
                  l.adoptionVisitsEmpty,
                  style: theme.textTheme.bodyMedium,
                ),
              );
            }
            return ListView.separated(
              itemCount: visits.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final visit = visits[index];
                return ListTile(
                  key: Key('adoption_visit_${visit['id']}'),
                  title: Text(visit['scheduled_at']?.toString() ?? ''),
                  subtitle: Text(
                    '${visit['status']} · ${visit['validation_status']}',
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
