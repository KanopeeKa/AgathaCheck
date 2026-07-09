import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/organization_providers.dart';

class OrganizationHomeHiddenPetsSection extends ConsumerStatefulWidget {
  const OrganizationHomeHiddenPetsSection({
    super.key,
    required this.orgId,
    required this.theme,
    required this.colorScheme,
    required this.l,
  });

  final String orgId;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final AppLocalizations l;

  @override
  ConsumerState<OrganizationHomeHiddenPetsSection> createState() =>
      _OrganizationHomeHiddenPetsSectionState();
}

class _OrganizationHomeHiddenPetsSectionState
    extends ConsumerState<OrganizationHomeHiddenPetsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hiddenAsync = ref.watch(orgHomeHiddenPetsProvider(widget.orgId));

    return hiddenAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (hiddenPets) {
        if (hiddenPets.isEmpty) return const SizedBox.shrink();
        return Card(
          color: AppTheme.orgBlueDarker,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  key: const Key('org_home_hidden_header'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    children: [
                      Icon(
                        Icons.home_outlined,
                        size: 20,
                        color: widget.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.l.homeHiddenPets,
                          style: widget.theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text('${hiddenPets.length}'),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                          color: widget.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_expanded) ...[
                  const SizedBox(height: 12),
                  ...hiddenPets.map(
                    (pet) => ListTile(
                      key: Key('home_hidden_${pet.petId}'),
                      title: Text(pet.petName),
                      trailing: TextButton(
                        onPressed: () async {
                          await ref
                              .read(
                                orgHomeHiddenPetsProvider(
                                  widget.orgId,
                                ).notifier,
                              )
                              .unhide(pet.petId);
                        },
                        child: Text(widget.l.unhide),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
