import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../widgets/all_care/all_care_closed_copy.dart';
import 'closed_care_list_body.dart';

/// Standalone closed care list (legacy push); prefer inline [ClosedCareListBody].
class ClosedCareListScreen extends ConsumerWidget {
  const ClosedCareListScreen({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(allCareClosedCareTitleLabel(l))),
      body: ClosedCareListBody(
        petId: petId,
        onBack: () => Navigator.of(context).pop(),
      ),
    );
  }
}
