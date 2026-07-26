import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../utils/org_screen_theme.dart';
import '../widgets/organization_connections_section.dart';

class OrganizationConnectionsScreen extends ConsumerWidget {
  const OrganizationConnectionsScreen({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return orgThemed(
      child: Scaffold(
        key: const Key('org_connections_screen'),
        appBar: AppBar(
          title: AppLogoTitle(title: l.orgConnections),
          leading: IconButton(
            key: const Key('org_connections_back'),
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => context.pop(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OrganizationConnectionsSection(
              orgId: orgId,
              theme: theme,
              colorScheme: colorScheme,
              l: l,
            ),
          ],
        ),
      ),
    );
  }
}
