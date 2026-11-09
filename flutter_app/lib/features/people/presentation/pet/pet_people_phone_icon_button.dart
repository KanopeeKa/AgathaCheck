import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';

/// Round 48×48 call control for pet profile people rows.
class PetPeoplePhoneIconButton extends StatelessWidget {
  const PetPeoplePhoneIconButton({
    super.key,
    required this.phone,
    required this.name,
    this.semanticsIdentifier,
  });

  final String phone;
  final String name;
  final String? semanticsIdentifier;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final label = '$name — ${l.peopleActionCall}';
    return Semantics(
      identifier: semanticsIdentifier,
      button: true,
      label: label,
      child: IconButton(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        tooltip: label,
        onPressed: () => _launchTel(context, phone.trim(), l),
        icon: const Icon(Icons.call_outlined),
      ),
    );
  }

  static Future<void> _launchTel(
    BuildContext context,
    String phone,
    AppLocalizations l,
  ) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (!await launchUrl(uri)) {
      await Clipboard.setData(ClipboardData(text: phone));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.peopleCopiedToClipboard)));
      }
    }
  }
}
