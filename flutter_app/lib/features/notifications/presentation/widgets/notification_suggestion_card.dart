import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/care/care_suggestion_display_copy.dart';
import 'package:pet_profile_app/core/widgets/agatha_message_card.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notification_providers.dart';

const _wireTypeCareFamily = 'suggestionCareFamily';

/// For you suggestion row (FR-SC-1).
class NotificationSuggestionCard extends ConsumerWidget {
  const NotificationSuggestionCard({
    super.key,
    required this.notification,
    required this.onOpenPet,
  });

  final AppNotification notification;
  final VoidCallback onOpenPet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (notification.wireType == _wireTypeCareFamily) {
      return _CareFamilySuggestionCard(notification: notification);
    }
    return _LegacyCompactSuggestionCard(
      notification: notification,
      onOpenPet: onOpenPet,
    );
  }
}

class _LegacyCompactSuggestionCard extends ConsumerStatefulWidget {
  const _LegacyCompactSuggestionCard({
    required this.notification,
    required this.onOpenPet,
  });

  final AppNotification notification;
  final VoidCallback onOpenPet;

  @override
  ConsumerState<_LegacyCompactSuggestionCard> createState() =>
      _LegacyCompactSuggestionCardState();
}

class _LegacyCompactSuggestionCardState
    extends ConsumerState<_LegacyCompactSuggestionCard> {
  bool _feedbackInFlight = false;

  Future<void> _submitFeedback(String value) async {
    if (_feedbackInFlight) return;
    setState(() => _feedbackInFlight = true);
    final l = AppLocalizations.of(context)!;
    try {
      await ref
          .read(notificationsProvider.notifier)
          .submitSuggestionFeedback(widget.notification.id, value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.careSuggestionRespondFailed)));
      }
    } finally {
      if (mounted) setState(() => _feedbackInFlight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final unread = widget.notification.isSuggestionUnread;

    return AgathaMessageCard(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      themeSuggestionActions: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.careSuggestionTitle,
                      style: AgathaMessageCardShell.titleStyle(theme.textTheme),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.notification.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: unread ? FontWeight.bold : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.notification.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (widget.notification.showsHealthAdjacentDisclaimer) ...[
                      const SizedBox(height: 6),
                      Text(
                        l.notificationSuggestionVetDisclaimer,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (_feedbackInFlight) return;
                  _submitFeedback(value);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'dismiss',
                    child: Text(l.careSuggestionDismiss),
                  ),
                  PopupMenuItem(
                    value: 'not_relevant',
                    child: Text(l.careSuggestionNotRelevant),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: widget.onOpenPet,
              child: Text(l.careSuggestionAccept),
            ),
          ),
        ],
      ),
    );
  }
}

class _CareFamilySuggestionCard extends ConsumerStatefulWidget {
  const _CareFamilySuggestionCard({required this.notification});

  final AppNotification notification;

  @override
  ConsumerState<_CareFamilySuggestionCard> createState() =>
      _CareFamilySuggestionCardState();
}

class _CareFamilySuggestionCardState
    extends ConsumerState<_CareFamilySuggestionCard> {
  bool _feedbackInFlight = false;

  AppNotification get notification => widget.notification;

  Map<String, dynamic> get _payload =>
      notification.suggestionPayload ?? const <String, dynamic>{};

  String get _suggestionKey => _payload['suggestion_key']?.toString() ?? '';

  String get _rationaleKey =>
      _payload['rationale_key']?.toString() ?? 'careSuggestionGenericWhy';

  String get _suggestedName =>
      _payload['suggested_name']?.toString() ?? notification.title;

  String get _frequency =>
      _payload['suggested_frequency']?.toString() ?? 'monthly';

  int get _frequencyInterval =>
      (_payload['suggested_frequency_interval'] as num?)?.toInt() ?? 1;

  String? get _recommendationId => _payload['recommendation_id']?.toString();

  String? get _careFamilyWire => _payload['care_family']?.toString();

  bool get _canAccept {
    final petId = notification.petId;
    final recId = _recommendationId;
    return petId != null &&
        petId.isNotEmpty &&
        recId != null &&
        recId.isNotEmpty;
  }

  void _onAccept(BuildContext context, AppLocalizations l) {
    if (!_canAccept) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.notificationSuggestionAcceptUnavailable)),
      );
      return;
    }
    _openReviewForm(context, l);
  }

  void _openReviewForm(BuildContext context, AppLocalizations l) {
    final petId = notification.petId!;
    final recId = _recommendationId!;
    final title = careSuggestionDisplayTitleForKey(
      l,
      suggestionKey: _suggestionKey,
      suggestedName: _suggestedName,
    );
    final uri = Uri(
      path: '/pet/$petId/care/add',
      queryParameters: {
        if (_careFamilyWire != null) 'family': _careFamilyWire!,
        'planning': 'planned',
        'careRecommendationId': recId,
        'name': title,
        'frequency': _frequency,
        'frequencyInterval': _frequencyInterval.toString(),
      },
    );
    GoRouter.of(context).push(uri.toString());
  }

  Future<void> _feedback(BuildContext context, String action) async {
    if (_feedbackInFlight) return;
    setState(() => _feedbackInFlight = true);
    final l = AppLocalizations.of(context)!;
    try {
      await ref
          .read(notificationsProvider.notifier)
          .submitSuggestionFeedback(notification.id, action);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.careSuggestionRespondFailed)));
      }
    } finally {
      if (mounted) setState(() => _feedbackInFlight = false);
    }
  }

  void _showWhy(BuildContext context, AppLocalizations l, String displayTitle) {
    final theme = Theme.of(context);
    final body = careSuggestionRationaleBody(l, _rationaleKey);
    final cadenceLabel = careSuggestionCadenceLabelFromWire(
      l,
      frequency: _frequency,
      interval: _frequencyInterval,
    );
    final petName = notification.petName;
    final hasPetName = petName != null && petName.isNotEmpty;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.careSuggestionWhyTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (hasPetName)
              Text(
                l.careSuggestionWhyForPet(petName),
                style: theme.textTheme.titleSmall,
              ),
            Text(
              cadenceLabel == null
                  ? displayTitle
                  : l.careSuggestionWhyRoutineSummary(
                      displayTitle,
                      cadenceLabel,
                    ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(body, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final displayTitle = careSuggestionDisplayTitleForKey(
      l,
      suggestionKey: _suggestionKey,
      suggestedName: _suggestedName,
    );
    final benefit = careSuggestionShortBenefitForRationale(
      l,
      rationaleKey: _rationaleKey,
    );
    final cadenceLabel = careSuggestionCadenceLabelFromWire(
      l,
      frequency: _frequency,
      interval: _frequencyInterval,
    );
    final eyebrowLabel =
        '${l.careSuggestionEyebrowAgatha} ${l.careSuggestionEyebrowRecommends}';
    final base = AgathaMessageCardShell.titleStyle(theme.textTheme);

    return AgathaMessageCard(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      themeSuggestionActions: true,
      child: Semantics(
        container: true,
        label: '$eyebrowLabel. $displayTitle',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: l.careSuggestionEyebrowAgatha,
                    style: base.copyWith(fontStyle: FontStyle.italic),
                  ),
                  TextSpan(
                    text: ' ${l.careSuggestionEyebrowRecommends}',
                    style: base,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              benefit,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 4,
                  ),
                  minimumSize: const Size(48, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showWhy(context, l, displayTitle),
                child: Text(l.careSuggestionWhyLink),
              ),
            ),
            if (cadenceLabel != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cadenceLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ] else
              const SizedBox(height: 8),
            FilledButton(
              onPressed: () => _onAccept(context, l),
              child: Text(l.careSuggestionAccept),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _feedbackInFlight
                        ? null
                        : () => _feedback(context, 'dismiss'),
                    child: Text(l.careSuggestionLater),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _feedbackInFlight
                        ? null
                        : () => _feedback(context, 'not_relevant'),
                    child: Text(l.careSuggestionNoThanks),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String formatPetGroupHeader(AppLocalizations l, String? petName) =>
    petName == null || petName.isEmpty ? l.petLabel : petName;
