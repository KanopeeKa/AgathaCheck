import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';
import '../services/consent_service.dart';
import 'consent/consent_banner_surface.dart';
import 'consent/consent_preferences_sheet.dart';
import 'consent/consent_settings_screen.dart';

export 'consent/consent_settings_screen.dart';

/// First-use cookie consent banner.
class ConsentBanner extends ConsumerStatefulWidget {
  const ConsentBanner({super.key});

  @override
  ConsumerState<ConsentBanner> createState() => _ConsentBannerState();
}

class _ConsentBannerState extends ConsumerState<ConsentBanner> {
  @override
  Widget build(BuildContext context) {
    final consent = ref.watch(consentServiceProvider);
    if (consent.hasResponded) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ConsentBannerSurface(
      l10n: l10n,
      theme: theme,
      onManagePreferences: () => _showPreferences(context),
      onAcceptAll: () => ref.read(consentServiceProvider.notifier).acceptAll(),
    );
  }

  void _showPreferences(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const ConsentPreferencesSheet(),
    );
  }
}
