import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization.dart';

class OrgCard extends StatelessWidget {
  const OrgCard({
    super.key,
    required this.organization,
    this.onTap,
  });

  final Organization organization;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final isPro = organization.type == OrganizationType.professional;

    String typeLabel(OrganizationType type) {
      switch (type) {
        case OrganizationType.professional:
          return l.orgTypeProfessional;
        case OrganizationType.charity:
          return l.orgTypeCharity;
      }
    }

    return MergeSemantics(
      child: Semantics(
        label: '${organization.name}, ${typeLabel(organization.type)}, '
            '${l.memberCount(organization.memberCount)}, ${l.petCount(organization.petCount)}',
        child: Card(
          key: Key('org_card_${organization.id}'),
          color: AppTheme.orgBlueDarker,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isPro ? AppTheme.orgIconBg : AppTheme.orgCharityBg,
                    child: Icon(
                      isPro ? Icons.business : Icons.volunteer_activism,
                      color: isPro ? AppTheme.orgIconFg : AppTheme.orgCharityFg,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organization.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _TypeBadge(type: organization.type, label: typeLabel(organization.type)),
                            const SizedBox(width: 8),
                            if (organization.isSuperUser)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.orgSuperUserBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, size: 12,
                                        color: AppTheme.orgSuperUserFg),
                                    const SizedBox(width: 2),
                                    Text(
                                      l.orgSuperUser,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.orgSuperUserFg,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.people_outline, size: 16,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              l.memberCount(organization.memberCount),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.pets, size: 16,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              l.petCount(organization.petCount),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ExcludeSemantics(
                    child: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, required this.label});
  final OrganizationType type;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isPro = type == OrganizationType.professional;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPro ? AppTheme.orgBadgeBg : AppTheme.orgCharityBadgeBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isPro ? AppTheme.orgBadgeFg : AppTheme.orgCharityBadgeFg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
