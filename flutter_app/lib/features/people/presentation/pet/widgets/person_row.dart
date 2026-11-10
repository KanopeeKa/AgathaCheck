import 'package:flutter/material.dart';

import '../../../../../core/widgets/role_pill.dart';
import '../../widgets/person_avatar.dart';
import '../../../domain/enums/contact_kind.dart';
import '../pet_people_phone_icon_button.dart';

/// One person or contact row in the pet profile people box.
class PersonRow extends StatelessWidget {
  const PersonRow({
    super.key,
    required this.name,
    required this.stableId,
    this.subtitle,
    this.pills = const [],
    this.photoUrl,
    this.contactKind = ContactKind.person,
    this.phone,
    this.semanticsCallId,
    this.tappable = true,
    this.onTap,
    this.leading,
  });

  final String name;
  final String stableId;
  final String? subtitle;
  final List<RolePill> pills;
  final String? photoUrl;
  final ContactKind contactKind;
  final String? phone;
  final String? semanticsCallId;
  final bool tappable;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhone = phone?.trim().isNotEmpty == true;

    Widget trailing;
    if (hasPhone) {
      trailing = PetPeoplePhoneIconButton(
        phone: phone!,
        name: name,
        semanticsIdentifier: semanticsCallId,
      );
    } else if (tappable && onTap != null) {
      trailing = const Icon(Icons.chevron_right);
    } else {
      trailing = const SizedBox(width: 24);
    }

    final avatar =
        leading ??
        PersonAvatar(
          name: name,
          stableId: stableId,
          kind: contactKind,
          photoUrl: photoUrl,
        );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: theme.textTheme.bodyLarge),
        if (subtitle != null && subtitle!.trim().isNotEmpty)
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (pills.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 4, children: pills),
        ],
      ],
    );

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(child: content),
            trailing,
          ],
        ),
      ),
    );

    if (!tappable || onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
