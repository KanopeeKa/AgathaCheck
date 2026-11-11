import 'package:flutter/material.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/widgets/async_state/labelled_progress.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Presentational first-use cookie consent banner surface.
class ConsentBannerSurface extends StatelessWidget {
  const ConsentBannerSurface({
    super.key,
    required this.l10n,
    required this.theme,
    required this.onManagePreferences,
    required this.onRejectOptional,
    required this.onAcceptAll,
    this.saving = false,
    this.saveFailed = false,
    this.savingLabel,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onManagePreferences;
  final VoidCallback onRejectOptional;
  final VoidCallback onAcceptAll;
  final bool saving;
  final bool saveFailed;
  final String? savingLabel;

  static const double _compactBreakpoint = 400;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Material(
        color: AppColorTokens.operationsSurface,
        elevation: 6,
        shadowColor: AppColorTokens.operationsOlive.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColorTokens.operationsOlive.withValues(alpha: 0.2),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.cookie_outlined,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.consentBannerTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColorTokens.operationsInk,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.consentBannerMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColorTokens.body,
                ),
              ),
              const SizedBox(height: 16),
              if (saveFailed) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.consentPreferencesSaveFailed,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (saving)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: LabelledProgress(
                    label: savingLabel ?? l10n.consentBannerSaving,
                    size: 28,
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final manage = _manageButton();
                    final reject = _rejectButton();
                    final accept = _acceptButton();

                    if (constraints.maxWidth < _compactBreakpoint) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          manage,
                          const SizedBox(height: 12),
                          reject,
                          const SizedBox(height: 12),
                          accept,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: manage),
                        const SizedBox(width: 8),
                        Expanded(child: reject),
                        const SizedBox(width: 8),
                        Expanded(child: accept),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _outlinedStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColorTokens.operationsOlive,
      side: const BorderSide(color: AppColorTokens.operationsOlive),
      minimumSize: const Size(48, 48),
    );
  }

  ButtonStyle _filledStyle() {
    return FilledButton.styleFrom(
      backgroundColor: AppColorTokens.operationsOlive,
      foregroundColor: AppColorTokens.inverse,
      minimumSize: const Size(48, 48),
    );
  }

  Widget _manageButton() {
    return OutlinedButton(
      onPressed: onManagePreferences,
      style: _outlinedStyle(),
      child: Text(l10n.consentManagePreferences),
    );
  }

  Widget _rejectButton() {
    return OutlinedButton(
      onPressed: onRejectOptional,
      style: _outlinedStyle(),
      child: Text(l10n.consentRejectOptional),
    );
  }

  Widget _filledAcceptButton() {
    return FilledButton(
      onPressed: onAcceptAll,
      style: _filledStyle(),
      child: Text(l10n.consentAcceptAll),
    );
  }

  Widget _acceptButton() => _filledAcceptButton();
}
