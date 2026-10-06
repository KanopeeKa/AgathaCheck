import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/notification_settings_matrix.dart';

/// Push transport (FCM/APNs/web) is deferred; matrix push toggles stay hidden.
const kNotificationPushTransportShipped = false;

class NotificationSettingsMatrixSection extends StatelessWidget {
  const NotificationSettingsMatrixSection({
    super.key,
    required this.matrix,
    required this.suggestionTypes,
    required this.agathaSuggestionsInApp,
    required this.pushOsDenied,
    required this.onMatrixChanged,
    required this.onSuggestionTypesChanged,
    required this.onAgathaInAppChanged,
  });

  final NotificationSettingsMatrix matrix;
  final Map<String, bool> suggestionTypes;
  final bool agathaSuggestionsInApp;
  final bool pushOsDenied;
  final ValueChanged<NotificationSettingsMatrix> onMatrixChanged;
  final ValueChanged<Map<String, bool>> onSuggestionTypesChanged;
  final ValueChanged<bool> onAgathaInAppChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            l.notificationSettingsMatrixTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            l.notificationSettingsMatrixHelp,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        _MatrixHeaderRow(l: l, theme: theme, showPush: kNotificationPushTransportShipped),
        ...NotificationMatrixCategory.values.map((category) {
          if (category == NotificationMatrixCategory.agathaSuggestions) {
            return _AgathaSuggestionsRow(
              l: l,
              theme: theme,
              channels: matrix.channel(category),
              agathaInApp: agathaSuggestionsInApp,
              pushOsDenied: pushOsDenied,
              suggestionTypes: suggestionTypes,
              onChannelsChanged: (ch) =>
                  onMatrixChanged(matrix.copyWithCategory(category, ch)),
              onAgathaInAppChanged: onAgathaInAppChanged,
              onSuggestionTypesChanged: onSuggestionTypesChanged,
            );
          }
          return _CategoryMatrixRow(
            l: l,
            theme: theme,
            category: category,
            channels: matrix.channel(category),
            pushOsDenied: pushOsDenied,
            showPush: kNotificationPushTransportShipped,
            onChanged: (ch) =>
                onMatrixChanged(matrix.copyWithCategory(category, ch)),
          );
        }),
        if (!kNotificationPushTransportShipped)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              l.notificationSettingsPushDeferredHelp,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            l.notificationSettingsAgathaComputationHelp,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _MatrixHeaderRow extends StatelessWidget {
  const _MatrixHeaderRow({
    required this.l,
    required this.theme,
    required this.showPush,
  });

  final AppLocalizations l;
  final ThemeData theme;
  final bool showPush;

  @override
  Widget build(BuildContext context) {
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              l.notificationSettingsColumnCategory,
              style: labelStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              l.notificationSettingsColumnInbox,
              style: labelStyle,
              textAlign: TextAlign.center,
            ),
          ),
          if (showPush)
            Expanded(
              flex: 2,
              child: Text(
                l.notificationSettingsColumnPush,
                style: labelStyle,
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            flex: 2,
            child: Text(
              l.notificationSettingsColumnEmail,
              style: labelStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryMatrixRow extends StatelessWidget {
  const _CategoryMatrixRow({
    required this.l,
    required this.theme,
    required this.category,
    required this.channels,
    required this.pushOsDenied,
    required this.showPush,
    required this.onChanged,
  });

  final AppLocalizations l;
  final ThemeData theme;
  final NotificationMatrixCategory category;
  final NotificationCategoryChannels channels;
  final bool pushOsDenied;
  final bool showPush;
  final ValueChanged<NotificationCategoryChannels> onChanged;

  String _title() {
    switch (category) {
      case NotificationMatrixCategory.invitesRequests:
        return l.notificationSettingsCategoryInvites;
      case NotificationMatrixCategory.accessMembership:
        return l.notificationSettingsCategoryAccess;
      case NotificationMatrixCategory.organisationFoster:
        return l.notificationSettingsCategoryOrg;
      case NotificationMatrixCategory.agathaSuggestions:
        return l.notificationSettingsCategorySuggestions;
      case NotificationMatrixCategory.accountSecurity:
        return l.notificationSettingsCategoryAccountSecurity;
      case NotificationMatrixCategory.subscription:
        return l.notificationSettingsCategorySubscription;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = channels.locked;
    final pushEnabled = channels.pushEnabled && !pushOsDenied && !locked;
    return Column(
      children: [
        ListTile(
          dense: true,
          title: Text(_title(), style: theme.textTheme.bodyMedium),
          subtitle: locked
              ? Text(
                  l.notificationSettingsMandatoryLock,
                  style: theme.textTheme.bodySmall,
                )
              : null,
          trailing: SizedBox(
            width: showPush ? 220 : 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Center(
                    child: channels.inboxAlways
                        ? Text(
                            l.notificationSettingsInboxAlways,
                            style: theme.textTheme.labelSmall,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                if (showPush)
                  Expanded(
                    child: Center(
                      child: locked
                          ? Icon(Icons.lock, size: 18, color: theme.disabledColor)
                          : Switch(
                              value: pushEnabled,
                              onChanged: pushOsDenied
                                  ? null
                                  : (v) => onChanged(
                                      channels.copyWith(pushEnabled: v),
                                    ),
                            ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: locked
                        ? Icon(Icons.lock, size: 18, color: theme.disabledColor)
                        : Switch(
                            value: channels.emailEnabled,
                            onChanged: (v) =>
                                onChanged(channels.copyWith(emailEnabled: v)),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _AgathaSuggestionsRow extends StatelessWidget {
  const _AgathaSuggestionsRow({
    required this.l,
    required this.theme,
    required this.channels,
    required this.agathaInApp,
    required this.pushOsDenied,
    required this.suggestionTypes,
    required this.onChannelsChanged,
    required this.onAgathaInAppChanged,
    required this.onSuggestionTypesChanged,
  });

  final AppLocalizations l;
  final ThemeData theme;
  final NotificationCategoryChannels channels;
  final bool agathaInApp;
  final bool pushOsDenied;
  final Map<String, bool> suggestionTypes;
  final ValueChanged<NotificationCategoryChannels> onChannelsChanged;
  final ValueChanged<bool> onAgathaInAppChanged;
  final ValueChanged<Map<String, bool>> onSuggestionTypesChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          title: Text(l.notificationSettingsCategorySuggestions),
          trailing: SizedBox(
            width: kNotificationPushTransportShipped ? 220 : 160,
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Switch(
                      value: agathaInApp,
                      onChanged: (v) {
                        onAgathaInAppChanged(v);
                        onChannelsChanged(channels.copyWith(inboxEnabled: v));
                      },
                    ),
                  ),
                ),
                if (kNotificationPushTransportShipped)
                  Expanded(
                    child: Center(
                      child: _SuggestionPushModeControl(
                        mode: channels.pushMode,
                        pushOsDenied: pushOsDenied,
                        enabled: agathaInApp,
                        onChanged: (mode) => onChannelsChanged(
                          channels.copyWith(pushMode: mode),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: Switch(
                      value: channels.emailEnabled,
                      onChanged: agathaInApp
                          ? (v) => onChannelsChanged(
                              channels.copyWith(emailEnabled: v),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (agathaInApp)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: ExpansionTile(
              title: Text(
                l.notificationSettingsSuggestionTypesTitle,
                style: theme.textTheme.bodyMedium,
              ),
              children: kSuggestionTypeKeys.map((key) {
                return SwitchListTile(
                  title: Text(_suggestionLabel(l, key)),
                  value: suggestionTypes[key] ?? true,
                  onChanged: (v) {
                    final next = Map<String, bool>.from(suggestionTypes);
                    next[key] = v;
                    onSuggestionTypesChanged(next);
                  },
                );
              }).toList(),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }

  String _suggestionLabel(AppLocalizations l, String key) {
    switch (key) {
      case 'suggestionMissingRecurringCare':
        return l.notificationSettingsSuggestionS1;
      case 'suggestionWeightTrend':
        return l.notificationSettingsSuggestionS2;
      case 'suggestionRepeatedSymptom':
        return l.notificationSettingsSuggestionS3;
      case 'suggestionOverduePattern':
        return l.notificationSettingsSuggestionS4;
      case 'suggestionStaleRecord':
        return l.notificationSettingsSuggestionS5;
      case 'suggestionCareFamily':
        return l.notificationSettingsSuggestionS6;
      case 'suggestionShareCoverage':
        return l.notificationSettingsSuggestionS7;
      default:
        return key;
    }
  }
}

class _SuggestionPushModeControl extends StatelessWidget {
  const _SuggestionPushModeControl({
    required this.mode,
    required this.pushOsDenied,
    required this.enabled,
    required this.onChanged,
  });

  final SuggestionPushMode mode;
  final bool pushOsDenied;
  final bool enabled;
  final ValueChanged<SuggestionPushMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (pushOsDenied) {
      return Icon(
        Icons.notifications_off,
        size: 18,
        color: Theme.of(context).disabledColor,
      );
    }
    return PopupMenuButton<SuggestionPushMode>(
      tooltip: l.notificationSettingsColumnPush,
      enabled: enabled,
      initialValue: mode,
      onSelected: onChanged,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: SuggestionPushMode.off,
          child: Text(l.notificationSettingsPushModeOff),
        ),
        PopupMenuItem(
          value: SuggestionPushMode.weeklyDigest,
          child: Text(l.notificationSettingsPushModeWeekly),
        ),
        PopupMenuItem(
          value: SuggestionPushMode.instant,
          child: Text(l.notificationSettingsPushModeInstant),
        ),
      ],
      child: Icon(
        Icons.tune,
        size: 20,
        color: enabled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).disabledColor,
      ),
    );
  }
}
