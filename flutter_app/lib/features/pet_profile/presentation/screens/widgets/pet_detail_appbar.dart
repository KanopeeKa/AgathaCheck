import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/widgets/app_logo_title.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/presentation/widgets/events_nav_icon_button.dart';

class PetDetailAppBar extends StatelessWidget {
  final String petName;
  final int unreadCount;
  final bool isOrgPet;
  final ThemeData theme;
  final dynamic authUser; // Replace with your AuthUser type
  final void Function(String) onMenuSelected;

  const PetDetailAppBar({
    super.key,
    required this.petName,
    required this.unreadCount,
    required this.isOrgPet,
    required this.theme,
    required this.authUser,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SliverAppBar(
      pinned: true,
      backgroundColor: isOrgPet ? AppTheme.orgBlue : null,
      title: AppLogoTitle(title: petName),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l.goBack,
        onPressed: () => context.go('/'),
      ),
      actions: [
        Stack(
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
          ],
        ),
        IconButton(
          icon: const Icon(Icons.local_hospital),
          tooltip: l.veterinarians,
          onPressed: () => context.go('/vets'),
        ),
        const EventsNavIconButton(),
        PopupMenuButton<String>(
          tooltip: l.userMenu,
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              ((authUser?.firstName?.isNotEmpty == true)
                      ? authUser!.firstName![0]
                      : (authUser?.lastName?.isNotEmpty == true
                            ? authUser!.lastName![0]
                            : authUser?.email[0] ?? 'U'))
                  .toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          onSelected: onMenuSelected,
          itemBuilder: (context) {
            final l = AppLocalizations.of(context)!;
            return [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authUser?.firstName?.isNotEmpty == true
                          ? authUser!.firstName!
                          : (authUser?.lastName?.isNotEmpty == true
                                ? authUser!.lastName!
                                : 'User'),
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      authUser?.email ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(value: 'details', child: Text(l.myDetails)),
              PopupMenuItem<String>(value: 'logout', child: Text(l.logOut)),
            ];
          },
        ),
      ],
    );
  }
}
