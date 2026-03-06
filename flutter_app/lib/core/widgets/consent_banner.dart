import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../services/consent_service.dart';

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

    return Material(
      elevation: 8,
      child: Container(
        width: double.infinity,
        color: theme.colorScheme.surfaceContainerHighest,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cookie_outlined,
                        color: theme.colorScheme.primary, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.consentBannerTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.consentBannerMessage,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showPreferences(context),
                        child: Text(l10n.consentManagePreferences),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          ref
                              .read(consentServiceProvider.notifier)
                              .acceptAll();
                        },
                        child: Text(l10n.consentAcceptAll),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPreferences(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const _ConsentPreferencesSheet(),
    );
  }
}

class _ConsentPreferencesSheet extends ConsumerStatefulWidget {
  const _ConsentPreferencesSheet();

  @override
  ConsumerState<_ConsentPreferencesSheet> createState() =>
      _ConsentPreferencesSheetState();
}

class _ConsentPreferencesSheetState
    extends ConsumerState<_ConsentPreferencesSheet> {
  late bool _analytics;
  late bool _marketing;

  @override
  void initState() {
    super.initState();
    final consent = ref.read(consentServiceProvider);
    _analytics = consent.analyticsConsent;
    _marketing = consent.marketingConsent;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.consentManagePreferences,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.consentPreferencesDescription,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                value: true,
                onChanged: null,
                title: Text(l10n.consentEssential),
                subtitle: Text(l10n.consentEssentialDescription),
                secondary: Icon(Icons.lock, color: theme.colorScheme.primary),
              ),
              const Divider(),
              SwitchListTile(
                value: _analytics,
                onChanged: (v) => setState(() => _analytics = v),
                title: Text(l10n.consentAnalytics),
                subtitle: Text(l10n.consentAnalyticsDescription),
                secondary: const Icon(Icons.analytics_outlined),
              ),
              const Divider(),
              SwitchListTile(
                value: _marketing,
                onChanged: (v) => setState(() => _marketing = v),
                title: Text(l10n.consentMarketing),
                subtitle: Text(l10n.consentMarketingDescription),
                secondary: const Icon(Icons.campaign_outlined),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ref
                        .read(consentServiceProvider.notifier)
                        .savePreferences(
                          analyticsConsent: _analytics,
                          marketingConsent: _marketing,
                        );
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n.consentSavePreferences),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class ConsentSettingsScreen extends ConsumerStatefulWidget {
  const ConsentSettingsScreen({super.key});

  @override
  ConsumerState<ConsentSettingsScreen> createState() =>
      _ConsentSettingsScreenState();
}

class _ConsentSettingsScreenState
    extends ConsumerState<ConsentSettingsScreen> {
  late bool _analytics;
  late bool _marketing;

  @override
  void initState() {
    super.initState();
    final consent = ref.read(consentServiceProvider);
    _analytics = consent.analyticsConsent;
    _marketing = consent.marketingConsent;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final consent = ref.watch(consentServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.consentSettings),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.consentPreferencesDescription,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (consent.consentTimestamp != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer
                          .withAlpha(120),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule,
                            size: 16,
                            color:
                                theme.colorScheme.onSecondaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.consentLastUpdated(
                                _formatTimestamp(consent.consentTimestamp!)),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: true,
                        onChanged: null,
                        title: Text(l10n.consentEssential),
                        subtitle:
                            Text(l10n.consentEssentialDescription),
                        secondary: Icon(Icons.lock,
                            color: theme.colorScheme.primary),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _analytics,
                        onChanged: (v) =>
                            setState(() => _analytics = v),
                        title: Text(l10n.consentAnalytics),
                        subtitle:
                            Text(l10n.consentAnalyticsDescription),
                        secondary:
                            const Icon(Icons.analytics_outlined),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _marketing,
                        onChanged: (v) =>
                            setState(() => _marketing = v),
                        title: Text(l10n.consentMarketing),
                        subtitle:
                            Text(l10n.consentMarketingDescription),
                        secondary:
                            const Icon(Icons.campaign_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      ref
                          .read(consentServiceProvider.notifier)
                          .savePreferences(
                            analyticsConsent: _analytics,
                            marketingConsent: _marketing,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(l10n.consentPreferencesSaved)),
                      );
                    },
                    child: Text(l10n.consentSavePreferences),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
