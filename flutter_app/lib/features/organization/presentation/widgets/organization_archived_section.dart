import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

class OrganizationArchivedSection extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final AppLocalizations l;
  final void Function()? onTap;

  const OrganizationArchivedSection({
    super.key,
    required this.theme,
    required this.colorScheme,
    required this.l,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: l.orgArchived,
      child: Card(
        color: AppTheme.orgBlueDarker,
        child: ListTile(
          key: const Key('org_view_archived'),
          leading: Icon(Icons.archive, color: colorScheme.onSurfaceVariant),
          title: Text(l.orgArchived),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
