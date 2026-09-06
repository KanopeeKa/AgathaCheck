import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_experience.dart';

/// Shelter workspace is always available in the shell (D-v5-WORKSPACE-1).
class ExperienceWorkspaceToggle extends ConsumerWidget {
  const ExperienceWorkspaceToggle({
    super.key,
    required this.currentLocation,
    required this.onDarkBackground,
    required this.showShelter,
  });

  final String currentLocation;
  final bool onDarkBackground;
  final bool showShelter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final isShelterRoute = currentLocation.startsWith('/o/');
    final activeExperience = isShelterRoute
        ? AppExperience.organization
        : AppExperience.petCare;
    final foreground = onDarkBackground
        ? AppColorTokens.inverse
        : AppColorTokens.body;
    final activeLabel = activeExperience == AppExperience.organization
        ? l.workspaceShelter
        : l.drawerPetCare;

    return Semantics(
      container: true,
      label: l.workspaceSwitcherLabel,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 112,
          height: 48,
          child: PopupMenuButton<AppExperience>(
            key: const Key('experience_workspace_toggle'),
            tooltip: l.workspaceSwitcherLabel,
            position: PopupMenuPosition.under,
            offset: const Offset(0, 4),
            padding: EdgeInsets.zero,
            color: activeExperience == AppExperience.organization
                ? AppColorTokens.organizationPrimary
                : AppColorTokens.petCarePrimary,
            // Width matches the pill; do not cap menu height (48px clipped Shelter).
            constraints: const BoxConstraints.tightFor(width: 112),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (selected) => _selectExperience(context, ref, selected),
            itemBuilder: (context) => [
              PopupMenuItem<AppExperience>(
                key: const Key('experience_workspace_menu_guardian'),
                value: AppExperience.petCare,
                child: Text(
                  l.drawerPetCare,
                  style: const TextStyle(color: AppColorTokens.inverse),
                ),
              ),
              if (showShelter)
                PopupMenuItem<AppExperience>(
                  key: const Key('experience_workspace_menu_shelter'),
                  value: AppExperience.organization,
                  child: Text(
                    l.workspaceShelter,
                    style: const TextStyle(color: AppColorTokens.inverse),
                  ),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: DecoratedBox(
                key: const Key('experience_workspace_pill'),
                decoration: ShapeDecoration(
                  shape: StadiumBorder(side: BorderSide(color: foreground)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        activeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textScaler: MediaQuery.textScalerOf(
                          context,
                        ).clamp(maxScaleFactor: 1.15),
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: foreground,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectExperience(
    BuildContext context,
    WidgetRef ref,
    AppExperience selected,
  ) async {
    final activeExperience = currentLocation.startsWith('/o/')
        ? AppExperience.organization
        : AppExperience.petCare;
    if (selected == activeExperience) return;

    if (!context.mounted) return;

    context.go(selected == AppExperience.petCare ? '/pc/home' : '/o/orgs');
  }
}
