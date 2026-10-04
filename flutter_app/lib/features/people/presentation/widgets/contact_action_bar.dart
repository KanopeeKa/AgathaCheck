import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';

/// Quick actions for a contact's phone, email, address, and website.
class ContactActionBar extends StatelessWidget {
  const ContactActionBar({
    super.key,
    this.phone,
    this.email,
    this.address,
    this.website,
  });

  final String? phone;
  final String? email;
  final String? address;
  final String? website;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final actions = <_ActionSpec>[];

    final phoneVal = phone?.trim() ?? '';
    if (phoneVal.isNotEmpty) {
      actions.add(
        _ActionSpec(
          id: 'call',
          label: l.peopleActionCall,
          icon: Icons.call_outlined,
          value: phoneVal,
          onTap: () => _launchTel(context, phoneVal, l),
        ),
      );
      actions.add(
        _ActionSpec(
          id: 'message',
          label: l.peopleActionMessage,
          icon: Icons.sms_outlined,
          value: phoneVal,
          onTap: () => _launchSms(context, phoneVal, l),
        ),
      );
    }

    final emailVal = email?.trim() ?? '';
    if (emailVal.isNotEmpty) {
      actions.add(
        _ActionSpec(
          id: 'email',
          label: l.peopleActionEmail,
          icon: Icons.mail_outline,
          value: emailVal,
          onTap: () => _launchMail(context, emailVal, l),
        ),
      );
    }

    final addressVal = address?.trim() ?? '';
    if (addressVal.isNotEmpty) {
      actions.add(
        _ActionSpec(
          id: 'directions',
          label: l.peopleActionDirections,
          icon: Icons.directions_outlined,
          value: addressVal,
          onTap: () => _launchMaps(context, addressVal, l),
        ),
      );
    }

    final websiteVal = website?.trim() ?? '';
    final overflow = websiteVal.isNotEmpty;

    if (actions.isEmpty && !overflow) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        for (final action in actions.take(4))
          Expanded(
            child: _ActionButton(action: action, l: l),
          ),
        if (overflow)
          IconButton(
            tooltip: l.peopleOpenWebsite,
            onPressed: () => _launchWebsite(context, websiteVal, l),
            icon: const Icon(Icons.more_horiz),
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
      ],
    );
  }

  static Future<void> _copy(
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
    if (!await launchUrl(uri)) await _copy(context, phone, l);
  }

  static Future<void> _launchSms(
    BuildContext context,
    String phone,
    AppLocalizations l,
  ) async {
    final uri = Uri(scheme: 'sms', path: phone.replaceAll(' ', ''));
    if (!await launchUrl(uri)) await _copy(context, phone, l);
  }

  static Future<void> _launchMail(
    BuildContext context,
    String email,
    AppLocalizations l,
  ) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(uri)) await _copy(context, email, l);
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
      await _copy(context, address, l);
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
      await _copy(context, website, l);
    }
  }
}

class _ActionSpec {
  const _ActionSpec({
    required this.id,
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String id;
  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.l});

  final _ActionSpec action;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'people_action_${action.id}',
      button: true,
      label: action.label,
      child: InkWell(
        onTap: action.onTap,
        onLongPress: () => ContactActionBar._copy(context, action.value, l),
        child: SizedBox(
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, size: 22),
              const SizedBox(height: 2),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
