import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/foster_placement.dart';
import '../../utils/foster_placement_display.dart';

class FosteringSessionListTile extends StatelessWidget {
  const FosteringSessionListTile({
    super.key,
    required this.placement,
    required this.onTap,
  });

  final FosterPlacement placement;
  final VoidCallback onTap;

  String _statusLabel(AppLocalizations l) {
    if (placement.derivedStatus == 'nearly_finished') {
      return l.fosteringSessionDerivedNearlyFinished;
    }
    return fosterSessionStatusLabel(l, placement.sessionStatus);
  }

  Future<void> _emailFoster(BuildContext context) async {
    final email = placement.fosterEmail.trim();
    if (email.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();

    final subtitleParts = <String>[
      if (placement.fosterName.isNotEmpty) placement.fosterName,
      if (placement.startDate != null) dateFormat.format(placement.startDate!),
      if (placement.endDate != null)
        '– ${dateFormat.format(placement.endDate!)}',
    ];

    return Card(
      key: Key('fostering_session_row_${placement.id}'),
      child: ListTile(
        onTap: onTap,
        title: Text(
          placement.petName.isNotEmpty ? placement.petName : l.orgPets,
        ),
        subtitle: subtitleParts.isEmpty
            ? null
            : Text(subtitleParts.join(' · ')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(_statusLabel(l)),
              visualDensity: VisualDensity.compact,
              backgroundColor: placement.nearlyFinished
                  ? colorScheme.tertiaryContainer
                  : colorScheme.surfaceContainerHighest,
            ),
            if (placement.fosterEmail.isNotEmpty)
              IconButton(
                key: Key('fostering_session_mail_${placement.id}'),
                icon: const Icon(Icons.mail_outline),
                tooltip: l.orgEmail,
                onPressed: () => _emailFoster(context),
              ),
          ],
        ),
      ),
    );
  }
}
