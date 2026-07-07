import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

class OrganizationHiddenSharedPetsSection extends StatelessWidget {
  final List<dynamic> orgHidden;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final AppLocalizations l;
  final bool hiddenExpanded;
  final void Function()? onToggleExpand;
  final void Function(dynamic pet)? onUnhide;

  const OrganizationHiddenSharedPetsSection({
    super.key,
    required this.orgHidden,
    required this.theme,
    required this.colorScheme,
    required this.l,
    required this.hiddenExpanded,
    this.onToggleExpand,
    this.onUnhide,
  });

  @override
  Widget build(BuildContext context) {
    if (orgHidden.isEmpty) return const SizedBox.shrink();
    return Card(
      color: AppTheme.orgBlueDarker,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              key: const Key('org_hidden_header'),
              borderRadius: BorderRadius.circular(8),
              onTap: onToggleExpand,
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_off,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.hiddenSharedPets,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${orgHidden.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: hiddenExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (hiddenExpanded) ...[
              const SizedBox(height: 12),
              ...orgHidden.map(
                (pet) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.pets,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Text(pet.name),
                    subtitle: Text(pet.species),
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.visibility, size: 18),
                      label: Text(l.unhide),
                      onPressed: () => onUnhide?.call(pet),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
