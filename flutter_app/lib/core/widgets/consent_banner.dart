import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';
import '../services/consent_service.dart';
import 'consent/consent_banner_surface.dart';
import 'consent/consent_preferences_sheet.dart';

export 'consent/consent_settings_screen.dart';

/// First-use cookie consent banner.
class ConsentBanner extends ConsumerStatefulWidget {
  const ConsentBanner({super.key});

  @override
  ConsumerState<ConsentBanner> createState() => _ConsentBannerState();
}

class _ConsentBannerState extends ConsumerState<ConsentBanner> {
  bool _saving = false;
  bool _saveFailed = false;

  @override
  Widget build(BuildContext context) {
    final consent = ref.watch(consentServiceProvider);
    if (consent.hasResponded) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ConsentBannerSurface(
      l10n: l10n,
      theme: theme,
      saving: _saving,
      saveFailed: _saveFailed,
      onManagePreferences: () => _showPreferences(context),
      onRejectOptional: _rejectOptional,
      onAcceptAll: () => ref.read(consentServiceProvider.notifier).acceptAll(),
    );
  }

  Future<void> _rejectOptional() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    final ok = await ref
        .read(consentServiceProvider.notifier)
        .savePreferences(analyticsConsent: false, marketingConsent: false);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _saving = false;
        _saveFailed = false;
      });
      return;
    }
    setState(() {
      _saving = false;
      _saveFailed = true;
    });
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
