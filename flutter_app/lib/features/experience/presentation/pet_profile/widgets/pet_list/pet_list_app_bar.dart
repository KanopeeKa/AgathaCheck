import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pet_profile_app/core/utils/constants.dart';
import 'package:pet_profile_app/core/widgets/app_logo_title.dart';
import 'package:pet_profile_app/features/auth/auth.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// App bar for the standalone pet list screen (not embedded in guardian shell).
class PetListAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const PetListAppBar({
    super.key,
    required this.unreadCount,
    required this.onLogout,
  });

  final int unreadCount;
  final Future<void> Function() onLogout;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return AppBar(
      title: const AppLogoTitle(title: AppConstants.appTitle),
      actions: [
        MergeSemantics(
          child: Semantics(
            label: unreadCount > 0
                ? '${l.notifications}, ${unreadCount > 99 ? '99+' : unreadCount} unread'
                : l.notifications,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: l.notifications,
                  onPressed: () => context.go('/notifications'),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.local_hospital),
          tooltip: l.veterinarians,
          onPressed: () => context.go('/vets'),
        ),
        const EventsNavIconButton(),
        IconButton(
          icon: const Icon(Icons.business),
          tooltip: l.organizations,
          onPressed: () => context.go('/organizations'),
        ),
        PopupMenuButton<String>(
          tooltip: l.userMenu,
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              ((auth.user?.firstName?.isNotEmpty == true)
                      ? auth.user!.firstName![0]
                      : (auth.user?.lastName?.isNotEmpty == true
                            ? auth.user!.lastName![0]
                            : auth.user?.email[0] ?? 'U'))
                  .toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          onSelected: (value) async {
            if (value == 'details') {
              context.push('/my-details');
            } else if (value == 'help') {
              context.push('/help');
            } else if (value == 'logout') {
              await onLogout();
            }
          },
          itemBuilder: (context) {
            final menuL = AppLocalizations.of(context)!;
            return [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.user?.firstName?.isNotEmpty == true
                          ? auth.user!.firstName!
                          : (auth.user?.lastName?.isNotEmpty == true
                                ? auth.user!.lastName!
                                : 'User'),
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      auth.user?.email ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'details',
                child: ListTile(
                  leading: const Icon(Icons.person_outlined),
                  title: Text(menuL.myDetails),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'help',
                child: ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(menuL.help),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(menuL.logOut),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ];
          },
        ),
      ],
    );
  }
}
