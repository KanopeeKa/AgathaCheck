import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/utils/resolve_static_asset_url.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/profile_photo_avatar.dart';
import '../../domain/entities/organization_member.dart';
import '../utils/org_person_role_bar.dart';
import 'org_foster_badge.dart';
import 'organization_role_labels.dart';

/// Pet-grid person tile: photo top 2/3; role bar + label, name, foster badge, optional phone.
class OrgPersonTile extends ConsumerWidget {
  const OrgPersonTile({
    super.key,
    required this.recordId,
    required this.displayName,
    required this.initials,
    this.photoUrl,
    this.role,
    this.isExternal = false,
    this.isPending = false,
    this.isSelf = false,
    this.selfCardLabel,
    this.phone,
    this.fosterApprovalState,
    this.fosterNeedsAttention = false,
    this.activeFosterCount = 0,
    this.semanticsLabel,
    this.onTap,
    this.trailing,
  });

  final String recordId;
  final String displayName;
  final String initials;
  final String? photoUrl;
  final OrgMemberRole? role;
  final bool isExternal;
  final bool isPending;
  final bool isSelf;
  final String? selfCardLabel;
  final String? phone;
  final String? fosterApprovalState;
  final bool fosterNeedsAttention;
  final int activeFosterCount;
  final String? semanticsLabel;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final showRoleBar = shouldShowOrgPersonRoleBar(
      role: role,
      isPending: isPending,
    );
    final roleLabel = showRoleBar && role != null
        ? localizedOrgMemberRole(l, role!)
        : (isPending ? l.invited : '');
    final barStyle = orgPersonRoleBarStyle(
      context,
      role: role,
      isPending: isPending,
    );
    final fosterBadge = fosterBadgeStateForPerson(
      isExternal: isExternal,
      fosterApprovalState: fosterApprovalState,
      fosterNeedsAttention: fosterNeedsAttention,
      activeFosterCount: activeFosterCount,
    );
    final resolvedPhoto = resolveStaticAssetUrl(
      photoUrl ?? '',
      apiBaseUrl: ref.read(apiBaseUrlProvider),
    );
    final showPhone = phone != null && phone!.trim().isNotEmpty;
    final label =
        semanticsLabel ??
        (isSelf
            ? l.adminContactsSelfCardSemantics(displayName)
            : l.adminContactsCardSemantics(
                displayName,
                roleLabel.isNotEmpty
                    ? roleLabel
                    : (fosterBadge != null
                          ? localizedOrgFosterBadgeLabel(l, fosterBadge)
                          : ''),
              ));

    return MergeSemantics(
      child: Semantics(
        identifier: 'org_person_tile_$recordId',
        button: onTap != null,
        label: label,
        child: Card(
          key: Key('org_person_tile_$recordId'),
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelf
                ? BorderSide(color: colorScheme.primary, width: 2)
                : BorderSide(color: colorScheme.outlineVariant.withAlpha(120)),
          ),
          child: InkWell(
            onTap: isPending ? null : onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _PhotoArea(
                        photoUrl: photoUrl,
                        resolvedPhotoUrl: resolvedPhoto,
                        initials: initials,
                        isPending: isPending,
                      ),
                      if (trailing != null)
                        Positioned(top: 4, right: 4, child: trailing!),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (roleLabel.isNotEmpty)
                          _RoleBar(label: roleLabel, style: barStyle),
                        if (isSelf) ...[
                          Text(
                            selfCardLabel ?? l.adminContactsYourCard,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              displayName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                fontStyle: isPending ? FontStyle.italic : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (fosterBadge != null)
                          OrgFosterBadge(state: fosterBadge),
                        if (showPhone)
                          Text(
                            phone!.trim(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoArea extends StatelessWidget {
  const _PhotoArea({
    required this.photoUrl,
    required this.resolvedPhotoUrl,
    required this.initials,
    required this.isPending,
  });

  final String? photoUrl;
  final String resolvedPhotoUrl;
  final String initials;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Image.network(
        resolvedPhotoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _SmileyFallback(initials: initials, isPending: isPending),
      );
    }
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: _SmileyFallback(initials: initials, isPending: isPending),
    );
  }
}

class _SmileyFallback extends StatelessWidget {
  const _SmileyFallback({required this.initials, required this.isPending});

  final String initials;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (initials != '?' && initials.isNotEmpty) {
      return Center(
        child: ProfilePhotoAvatar(
          photoUrl: null,
          initials: initials,
          radius: 28,
        ),
      );
    }
    return Center(
      child: Icon(
        isPending
            ? Icons.hourglass_empty
            : Icons.sentiment_satisfied_alt_outlined,
        size: 40,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _RoleBar extends StatelessWidget {
  const _RoleBar({required this.label, required this.style});

  final String label;
  final OrgPersonRoleBarStyle style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        key: Key('org_person_role_bar_$label'),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: style.barColor,
          borderRadius: BorderRadius.circular(4),
          border: style.borderColor != null
              ? Border.all(color: style.borderColor!)
              : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: style.labelColor,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
