import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';

/// Chevron navigation rows for Timeline, Weight tracking, and Health issues.
class PetProfileSectionNav extends StatelessWidget {
  const PetProfileSectionNav({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            ListTile(
              key: const Key('pet_profile_nav_timeline'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.petTimelineTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/pet/$petId/timeline'),
            ),
            const Divider(height: 1),
            ListTile(
              key: const Key('pet_profile_nav_weight'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.weightTracking),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/pet/$petId/weight'),
            ),
            const Divider(height: 1),
            ListTile(
              key: const Key('pet_profile_nav_health_issues'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.healthIssues),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/pet/$petId/health-issues'),
            ),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }
}
