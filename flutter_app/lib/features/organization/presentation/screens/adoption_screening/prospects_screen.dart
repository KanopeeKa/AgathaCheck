import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/app_logo_title.dart';
import '../../providers/org_provider_deps.dart';
import '../../utils/org_screen_theme.dart';

class ProspectsScreen extends ConsumerWidget {
  const ProspectsScreen({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(orgTokenProvider);
    final theme = Theme.of(context);
    return orgThemed(
      child: Scaffold(
        appBar: AppBar(
          title: const AppLogoTitle(title: 'Prospects'),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: token == null
              ? Future.value(const [])
              : ref
                    .read(organizationRepositoryProvider)
                    .getProspects(orgId, token),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            }
            final prospects = snapshot.data ?? const [];
            if (prospects.isEmpty) {
              return Center(
                child: Text(
                  'No prospects yet',
                  style: theme.textTheme.bodyMedium,
                ),
              );
            }
            return ListView.separated(
              itemCount: prospects.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final prospect = prospects[index];
                return ListTile(
                  key: Key('prospect_${prospect['id']}'),
                  title: Text(prospect['display_name']?.toString() ?? ''),
                  subtitle: Text(prospect['email']?.toString() ?? ''),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
