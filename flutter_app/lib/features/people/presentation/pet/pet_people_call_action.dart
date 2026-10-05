import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';

/// One-tap call for pet emergency rows; hidden when [phone] is empty.
class PetPeopleCallAction extends StatelessWidget {
  const PetPeopleCallAction({
    super.key,
    required this.phone,
    this.semanticsIdentifier,
  });

  final String? phone;
  final String? semanticsIdentifier;

  @override
  Widget build(BuildContext context) {
    final trimmed = phone?.trim() ?? '';
    if (trimmed.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    return Semantics(
      identifier: semanticsIdentifier,
      button: true,
      label: l.peopleActionCall,
      child: TextButton.icon(
        onPressed: () => _launchTel(context, trimmed, l),
        icon: const Icon(Icons.call_outlined, size: 18),
        label: Text(l.peopleActionCall),
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
