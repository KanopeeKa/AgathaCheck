import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/app_experience.dart';
import '../config/drawer_menu_config.dart';
import '../providers/experience_providers.dart';
import '../../domain/entities/drawer_menu_item.dart';

/// Shared navigation for config-driven experience drawer rows.
Future<void> handleExperienceDrawerItemTap(
  BuildContext context,
  WidgetRef ref,
  DrawerMenuItem item,
) async {
  Navigator.pop(context);

  switch (item.semanticKey) {
    case 'drawer_contact':
      final uri = Uri(scheme: 'mailto', path: DrawerMenuConfig.contactEmail);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      return;
    case 'drawer_logout':
      await ref.read(authProvider.notifier).logout();
      return;
    case 'drawer_org_view':
      ref.read(activeExperienceProvider.notifier).state =
          AppExperience.organization;
      context.go('/o/orgs');
      return;
    case 'drawer_guardian_view':
      ref.read(activeExperienceProvider.notifier).state =
          AppExperience.guardian;
      context.go(AppExperience.guardian.homePath());
      return;
  }

  final route = item.route;
  if (route == null) return;

  if (_useGoNavigation(route)) {
    context.go(route);
  } else {
    context.push(route);
  }
}

bool _useGoNavigation(String route) {
  return route == AppExperience.guardian.homePath() ||
      route == AppExperience.organization.homePath() ||
      route == AppExperience.guardian.eventsPath ||
      route == AppExperience.organization.eventsPath ||
      route == '/o/orgs' ||
      route == '/organizations' ||
      route == DrawerMenuConfig.legacyVetsPath;
}
