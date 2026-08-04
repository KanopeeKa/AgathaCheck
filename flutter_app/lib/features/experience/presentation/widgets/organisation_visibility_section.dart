import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/services/organisation_section_visibility.dart';
import '../providers/experience_providers.dart';

/// Account Preferences: show organisation section toggle (D-v3-VIS-1).
class OrganisationVisibilitySection extends ConsumerWidget {
  const OrganisationVisibilitySection({super.key, this.embedded = false});

  /// When true, omits the outer [Card] for use inside [DashboardSection].
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasMembership = ref.watch(hasOrgMembershipProvider);
    final showSection = ref.watch(showOrganisationSectionProvider);
    final toggleEnabled =
        OrganisationSectionVisibility.toggleEnabled(hasOrgMembership: hasMembership);
    final store = ref.read(experiencePreferencesStoreProvider);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!embedded) ...[
          Text(
            l.experienceShowOrganisationSectionTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
        ],
        Text(
          l.experienceShowOrganisationSectionSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (embedded) const SizedBox(height: 8),
        SwitchListTile(
          key: const Key('show_organisation_section_toggle'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.experienceShowOrganisationSectionTitle),
          value: showSection,
          onChanged: toggleEnabled
              ? (value) async {
                  await store.writeShowOrganisationSection(value);
                  ref.invalidate(showOrganisationSectionPrefProvider);
                }
              : null,
        ),
        if (!toggleEnabled) ...[
          const SizedBox(height: 4),
          Text(
            l.experienceShowOrganisationSectionMemberLocked,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    if (embedded) return content;

    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: content),
    );
  }
}
