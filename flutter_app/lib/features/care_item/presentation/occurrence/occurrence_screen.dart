import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/analytics_providers.dart';
import '../../../../core/router/shell_return_navigation.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/care_command_outcome.dart';
import '../../application/care_item_providers.dart';
import '../../domain/occurrence_detail.dart';
import '../../domain/occurrence_display.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'occurrence_blocks.dart';
import 'occurrence_screen_menu.dart';
import 'occurrence_screen_menu_actions.dart';

CareItemStatusTone _occurrencePillTone(OccurrencePillTone tone) =>
    switch (tone) {
      OccurrencePillTone.overdue => CareItemStatusTone.overdue,
      OccurrencePillTone.due => CareItemStatusTone.due,
      OccurrencePillTone.notRecorded => CareItemStatusTone.notRecorded,
      OccurrencePillTone.closedNotRecorded =>
        CareItemStatusTone.notRecordedClosed,
      OccurrencePillTone.neutral => CareItemStatusTone.neutral,
    };

/// One occurrence, every status (D-CIE-029, §18.6.4). Loads
/// `GET …/occurrences/:occId`; actions reload it after the server confirms.
class OccurrenceScreen extends ConsumerStatefulWidget {
  const OccurrenceScreen({
    super.key,
    required this.petId,
    required this.entryId,
    required this.occurrenceId,
    this.focus,
  });

  final String petId;
  final String entryId;
  final String occurrenceId;

  /// `weight` focuses the weight field; `date` the date field.
  final String? focus;

  @override
  ConsumerState<OccurrenceScreen> createState() => _OccurrenceScreenState();
}

class _OccurrenceScreenState extends ConsumerState<OccurrenceScreen> {
  CareOutcome<OccurrenceDetail>? _outcome;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = GoRouter.maybeOf(context);
      if (router == null) return;
      final source =
          router
              .routerDelegate
              .currentConfiguration
              .uri
              .queryParameters['source'] ??
          'unknown';
      ref.read(analyticsServiceProvider).capture('occurrence_screen_opened', {
        'source': source,
      });
    });
  }

  Future<void> _load() async {
    final outcome = await ref
        .read(careCompletionServiceProvider)
        .fetchOccurrence(
          entryId: widget.entryId,
          occurrenceId: widget.occurrenceId,
        );
    if (mounted) setState(() => _outcome = outcome);
  }

  Future<void> _changed() async {
    await ref.read(careDataChangedProvider)();
    await _load();
  }

  void _openItem() =>
      openPetEventView(context, petId: widget.petId, entryId: widget.entryId);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final outcome = _outcome;
    final OccurrenceDetail? loadedDetail = switch (outcome) {
      CareSucceeded(:final value) => value,
      _ => null,
    };
    final title = loadedDetail?.item.name ?? '';
    return Semantics(
      identifier: 'occurrence_screen',
      child: Scaffold(
        key: const Key('occurrence_screen'),
        appBar: AppBar(
          title: Text(title),
          actions: [
            if (loadedDetail != null)
              OccurrenceScreenMenu(
                occurrenceId: widget.occurrenceId,
                onSelected: (action) => handleOccurrenceScreenMenuAction(
                  context,
                  ref,
                  loadedDetail,
                  action,
                  _changed,
                ),
              ),
          ],
          leading: BackButton(
            onPressed: () {
              final router = GoRouter.maybeOf(context);
              handleShellBack(
                context,
                returnTo: router == null
                    ? null
                    : shellReturnToFromState(GoRouterState.of(context)),
                defaultPath: '/pet/${widget.petId}/events/${widget.entryId}',
              );
            },
          ),
        ),
        body: switch (outcome) {
          null => const Center(child: CircularProgressIndicator()),
          CareFailed(failure: CareNotOpenFailure(gone: true)) => _Message(
            key: const Key('occurrence_gone'),
            text: l.occurrenceGone,
            actionLabel: l.occurrenceAboutItem,
            onAction: _openItem,
          ),
          CareFailed() => _Message(
            key: const Key('occurrence_error'),
            text: l.careOccurrenceLoadError,
            actionLabel: l.careRetry,
            onAction: () {
              setState(() => _outcome = null);
              _load();
            },
          ),
          CareSucceeded(:final value) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Header(detail: value, onOpenItem: _openItem),
              const SizedBox(height: 16),
              OccurrenceBlocks(
                detail: value,
                focus: widget.focus,
                onChanged: _changed,
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail, required this.onOpenItem});

  final OccurrenceDetail detail;
  final VoidCallback onOpenItem;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final occ = detail.occurrence;
    final pill = occ.isClosedNotRecorded
        ? closedNotRecordedPillStyle(l)
        : openOccurrencePillStyle(l, occ.status);
    final when = [DateFormat.yMMMd().format(occ.date), ?occ.time].join(' · ');
    return Semantics(
      identifier: 'occurrence_about_item',
      header: true,
      label: '${detail.item.name}. ${pill.label}. $when',
      child: InkWell(
        key: const Key('occurrence_about_item'),
        onTap: onOpenItem,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail.item.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        CareItemStatusPill(
                          key: const Key('occurrence_status'),
                          label: pill.label,
                          tone: _occurrencePillTone(pill.tone),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            when,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: l.occurrenceAboutItem,
                child: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
