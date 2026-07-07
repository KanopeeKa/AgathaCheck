import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_logo_title.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../health_tracking/presentation/widgets/events_nav_icon_button.dart';
import '../../../../notifications/presentation/providers/notification_providers.dart';

/// The pinned [SliverAppBar] for the pet detail screen, including the
/// notifications badge, quick-nav actions, and the user account menu.
class PetDetailAppBar extends ConsumerWidget {
  const PetDetailAppBar({
    super.key,
    required this.petName,
    required this.isOrgPet,
  });

  final String petName;
  final bool isOrgPet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

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
            } else if (value == 'logout') {
              await ref.read(authProvider.notifier).logout();
            }
          },
          itemBuilder: (context) {
            final l = AppLocalizations.of(context)!;
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
                  title: Text(l.myDetails),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(l.logOut),
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
