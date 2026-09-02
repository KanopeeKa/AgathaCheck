import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Sticky bottom bar for guardian pets: primary add action (⅔) + overflow (⅓).
class GuardianBottomActionBar extends StatelessWidget {
  const GuardianBottomActionBar({
    super.key,
    required this.onAddPet,
    required this.onSharePets,
  });

  final VoidCallback onAddPet;
  final VoidCallback onSharePets;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  key: const Key('add_pet_button'),
                  onPressed: onAddPet,
                  icon: const Icon(Icons.add),
                  label: Text(l.addPet),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: MenuAnchor(
                  key: const Key('pets_more_actions_menu'),
                  builder: (context, controller, child) {
                    return Tooltip(
                      message: l.moreActions,
                      child: OutlinedButton(
                        key: const Key('pets_more_actions_button'),
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Icon(Icons.more_horiz),
                      ),
                    );
                  },
                  menuChildren: [
                    MenuItemButton(
                      key: const Key('share_pets_menu_item'),
                      onPressed: onSharePets,
                      child: Text(l.sharePetsMenu),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
