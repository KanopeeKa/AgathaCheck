import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';

/// Eyebrow section header for Shelter hub sections on the teal canvas.
class OrgHubSectionHeader extends StatelessWidget {
  const OrgHubSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.titleColor = AppColorTokens.organizationPrimary,
  });

  final String title;
  final String? subtitle;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
