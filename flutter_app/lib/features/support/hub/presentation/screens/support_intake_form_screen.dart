import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_logo_title.dart';
import '../../../../../l10n/app_localizations.dart';

/// Route placeholder for the support intake form (implemented in execute-plan phase 4).
class SupportIntakeFormScreen extends StatelessWidget {
  const SupportIntakeFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: AppLogoTitle(title: l.contactHubHelpSupportTitle)),
      body: const SizedBox.shrink(),
    );
  }
}
