import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pet_profile_app/core/experience/app_experience.dart';
import 'package:pet_profile_app/core/providers/analytics_providers.dart';
import 'package:pet_profile_app/core/router/experience_shell_scaffold.dart';
import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'occurrence_reschedule.dart';
import 'occurrence_screen_body.dart';

/// One occurrence, every status (D-CIE-029, Care date screen spec).
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
  bool _busy = false;

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

  Future<void> _reschedule(OccurrenceDetail detail) async {
    setState(() => _busy = true);
    try {
      await rescheduleOccurrenceDate(
        context: context,
        ref: ref,
        detail: detail,
        onChanged: _changed,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final outcome = _outcome;
    final router = GoRouter.maybeOf(context);
    final location =
        router?.routerDelegate.currentConfiguration.uri.path ??
        '/pet/${widget.petId}/events/${widget.entryId}/occurrences/${widget.occurrenceId}';

    Widget content = switch (outcome) {
      null => const Center(child: CircularProgressIndicator()),
      CareFailed(failure: CareNotOpenFailure(gone: true)) => _Message(
        key: const Key('occurrence_gone'),
        text: l.occurrenceGone,
        actionLabel: l.occurrenceOpenCareDetails,
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
      CareSucceeded(:final value) => OccurrenceScreenBody(
        petId: widget.petId,
        entryId: widget.entryId,
        detail: value,
        focus: widget.focus,
        onChanged: _changed,
        onOpenCareDetails: _openItem,
        rescheduleBusy: _busy,
        onReschedule: () => _reschedule(value),
      ),
    };

    return Semantics(
      identifier: 'occurrence_screen',
      container: true,
      label: l.careDateScreenTitle,
      explicitChildNodes: true,
      child: ExperienceShellScaffold(
        key: const Key('occurrence_screen'),
        experience: AppExperience.petCare,
        currentLocation: location,
        screenTitle: l.careDateScreenTitle,
        backPath: '/pet/${widget.petId}/events/${widget.entryId}',
        child: content,
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
