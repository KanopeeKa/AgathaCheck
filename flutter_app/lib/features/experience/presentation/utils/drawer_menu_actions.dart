import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
    // Phase 1 unified section switcher entries
    case 'drawer_guardian':
      ref.read(activeExperienceProvider.notifier).state =
          AppExperience.guardian;
      context.go(AppExperience.guardian.homePath());
      return;
    case 'drawer_organisation':
      ref.read(activeExperienceProvider.notifier).state =
          AppExperience.organization;
      context.go('/o/orgs');
      return;
    case 'drawer_account':
      context.go('/account');
      return;

    // Legacy contact handler (still used in account_screen.dart)
    case 'drawer_contact':
      final uri = Uri(scheme: 'mailto', path: DrawerMenuConfig.contactEmail);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
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
      route == '/o/orgs' ||
      route == '/account' ||
      route == '/organizations';
}
