import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';

/// Contact information rows with dedicated action buttons (call, email, maps, web).
class PeopleContactCoordinatesSection extends StatelessWidget {
  const PeopleContactCoordinatesSection({
    super.key,
    required this.phone,
    required this.email,
    required this.address,
    required this.website,
  });

  final String? phone;
  final String? email;
  final String? address;
  final String? website;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rows = <Widget>[];

    void addRow({
      required IconData icon,
      required String label,
      required String value,
      VoidCallback? onAction,
      IconData actionIcon = Icons.open_in_new,
      String? actionTooltip,
    }) {
      if (value.trim().isEmpty) return;
      rows.add(
        _CoordinateRow(
          icon: icon,
          label: label,
          value: value.trim(),
          onAction: onAction,
          actionIcon: actionIcon,
          actionTooltip: actionTooltip,
          onCopy: () => _copyToClipboard(context, value.trim(), l),
        ),
      );
    }

    final phoneVal = phone?.trim() ?? '';
    if (phoneVal.isNotEmpty) {
      addRow(
        icon: Icons.phone_outlined,
        label: l.peoplePhoneLabel,
        value: phoneVal,
        onAction: () => _launchTel(context, phoneVal, l),
        actionIcon: Icons.call_outlined,
        actionTooltip: l.adminContactsCall,
      );
    }

    final emailVal = email?.trim() ?? '';
    if (emailVal.isNotEmpty) {
      addRow(
        icon: Icons.email_outlined,
        label: l.peopleEmailLabel,
        value: emailVal,
        onAction: () => _launchMail(context, emailVal, l),
        actionIcon: Icons.mail_outline,
        actionTooltip: l.vetEmail,
      );
    }

    final addressVal = address?.trim() ?? '';
    if (addressVal.isNotEmpty) {
      addRow(
        icon: Icons.location_on_outlined,
        label: l.peopleAddressLabel,
        value: addressVal,
        onAction: () => _launchMaps(context, addressVal, l),
        actionIcon: Icons.directions_outlined,
        actionTooltip: l.peopleOpenDirections,
      );
    }

    final websiteVal = website?.trim() ?? '';
    if (websiteVal.isNotEmpty) {
      addRow(
        icon: Icons.language_outlined,
        label: l.peopleWebsiteLabel,
        value: websiteVal,
        onAction: () => _launchWebsite(context, websiteVal, l),
        actionIcon: Icons.open_in_new,
        actionTooltip: l.peopleOpenWebsite,
      );
    }

    if (rows.isEmpty) {
      return Text(
        l.peopleContactInfoEmpty,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.peopleContactInformationTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }

  static Future<void> _copyToClipboard(
    BuildContext context,
    String value,
    AppLocalizations l,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.peopleCopiedToClipboard)));
    }
  }

  static Future<void> _launchTel(
    BuildContext context,
    String phone,
    AppLocalizations l,
  ) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (!await launchUrl(uri)) {
      await _copyToClipboard(context, phone, l);
    }
  }

  static Future<void> _launchMail(
    BuildContext context,
    String email,
    AppLocalizations l,
  ) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(uri)) {
      await _copyToClipboard(context, email, l);
    }
  }

  static Future<void> _launchMaps(
    BuildContext context,
    String address,
    AppLocalizations l,
  ) async {
    final query = Uri.encodeComponent(address);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await _copyToClipboard(context, address, l);
    }
  }

  static Future<void> _launchWebsite(
    BuildContext context,
    String website,
    AppLocalizations l,
  ) async {
    final normalized = website.startsWith('http')
        ? website
        : 'https://$website';
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await _copyToClipboard(context, website, l);
    }
  }
}

class _CoordinateRow extends StatelessWidget {
  const _CoordinateRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onAction,
    required this.actionIcon,
    this.actionTooltip,
    required this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final String? actionTooltip;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          if (onAction != null)
            IconButton(
              tooltip: actionTooltip,
              onPressed: onAction,
              icon: Icon(actionIcon),
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
        ],
      ),
    );
  }
}
