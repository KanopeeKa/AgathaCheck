import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Frozen MVP: organisation settings are not exposed in the active product.
class AccountOrganisationSettingsSection extends StatelessWidget {
  const AccountOrganisationSettingsSection({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Text(
      l.accountOrgSettingsEmpty,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
