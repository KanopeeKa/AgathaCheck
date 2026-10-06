import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../services/consent_service.dart';
import '../../theme/app_color_tokens.dart';

class ConsentPreferencesSheet extends ConsumerStatefulWidget {
  const ConsentPreferencesSheet({super.key});

  @override
  ConsumerState<ConsentPreferencesSheet> createState() =>
      _ConsentPreferencesSheetState();
}

class _ConsentPreferencesSheetState
    extends ConsumerState<ConsentPreferencesSheet> {
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: AppColorTokens.operationsSurface,
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
                    color: AppColorTokens.operationsInk,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.consentPreferencesDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColorTokens.body,
                  ),
                ),
                const SizedBox(height: 16),
                if (consent.consentTimestamp != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withAlpha(
                        120,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.consentLastUpdated(
                              _formatTimestamp(consent.consentTimestamp!),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
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
                        subtitle: Text(l10n.consentEssentialDescription),
                        secondary: Icon(
                          Icons.lock,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _analytics,
                        onChanged: (v) => setState(() => _analytics = v),
                        title: Text(l10n.consentAnalytics),
                        subtitle: Text(l10n.consentAnalyticsDescription),
                        secondary: const Icon(
                          Icons.analytics_outlined,
                          color: AppColorTokens.operationsOlive,
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _marketing,
                        onChanged: (v) => setState(() => _marketing = v),
                        title: Text(l10n.consentMarketing),
                        subtitle: Text(l10n.consentMarketingDescription),
                        secondary: const Icon(
                          Icons.campaign_outlined,
                          color: AppColorTokens.operationsGold,
                        ),
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
                        SnackBar(content: Text(l10n.consentPreferencesSaved)),
                      );
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColorTokens.operationsOlive,
                      foregroundColor: AppColorTokens.inverse,
                    ),
                    child: Text(l10n.consentSavePreferences),
                  ),
                ),
                const SizedBox(height: 8),
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
