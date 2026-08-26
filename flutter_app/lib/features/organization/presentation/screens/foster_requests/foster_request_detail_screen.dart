import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/foster_request.dart';
import '../../providers/foster_requests_providers.dart';
import 'foster_requests_screen.dart';
import '../../widgets/org_shell_app_bar_title.dart';
import '../../widgets/org_shell_scaffold.dart';

class FosterRequestDetailScreen extends ConsumerWidget {
  const FosterRequestDetailScreen({
    super.key,
    required this.orgId,
    required this.requestId,
  });

  final String orgId;
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final key = (orgId: orgId, requestId: requestId);
    final requestAsync = ref.watch(orgFosterRequestDetailProvider(key));

    return OrgShellScaffold(
      title: l.fosterRequestDetailTitle,
      orgId: orgId,
      navVariant: OrgNavTitleVariant.withOrgLogo,
      leadingKey: const Key('foster_request_detail_back'),
      child: requestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (request) =>
            _FosterRequestDetailBody(orgId: orgId, request: request),
      ),
    );
  }
}

class _FosterRequestDetailBody extends ConsumerStatefulWidget {
  const _FosterRequestDetailBody({required this.orgId, required this.request});

  final String orgId;
  final FosterRequest request;

  @override
  ConsumerState<_FosterRequestDetailBody> createState() =>
      _FosterRequestDetailBodyState();
}

class _FosterRequestDetailBodyState
    extends ConsumerState<_FosterRequestDetailBody> {
  var _sending = false;

  Future<void> _sendDraft() async {
    setState(() => _sending = true);
    final l = AppLocalizations.of(context)!;
    try {
      await ref
          .read(
            orgFosterRequestDetailProvider((
              orgId: widget.orgId,
              requestId: widget.request.id,
            )).notifier,
          )
          .sendDraft();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.fosterRequestSendSuccess)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final request = widget.request;
    final targetNames = {
      for (final t in request.targets) t.orgFosterParentId: t.displayName,
    };

    return ListView(
      key: const Key('foster_request_detail_body'),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Chip(label: Text(localizedFosterRequestStatus(l, request.status))),
            if (request.isDraft) ...[
              const Spacer(),
              FilledButton(
                key: const Key('foster_request_send_draft'),
                onPressed: _sending ? null : _sendDraft,
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.fosterRequestSendNow),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Text(l.fosterRequestMessageLabel, style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(request.message, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        Text(l.fosterRequestPetsSection, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (request.pets.isEmpty)
          Text(
            l.fosterRequestNoPets,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          )
        else
          ...request.pets.map(
            (pet) => ListTile(
              key: Key('foster_request_pet_${pet.petId}'),
              leading: const Icon(Icons.pets),
              title: Text(pet.petName.isNotEmpty ? pet.petName : pet.petId),
              subtitle: pet.species != null ? Text(pet.species!) : null,
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const SizedBox(height: 16),
        Text(l.fosterRequestTargetsSection, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (request.targets.isEmpty)
          Text(
            l.fosterRequestTargetsSummary(
              request.targetCount,
              request.responseSummary.canHelp,
              request.responseSummary.cannotHelp,
              request.responseSummary.pending,
            ),
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          )
        else
          ...request.targets.map(
            (target) => ListTile(
              key: Key('foster_request_target_${target.orgFosterParentId}'),
              leading: const Icon(Icons.person_outline),
              title: Text(target.displayName),
              subtitle: target.email != null ? Text(target.email!) : null,
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const SizedBox(height: 16),
        Text(
          l.fosterRequestResponsesSection,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (request.responses.isEmpty)
          Text(
            l.fosterRequestNoResponses,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          )
        else
          ...request.responses.map((response) {
            final name =
                targetNames[response.orgFosterParentId] ??
                response.orgFosterParentId;
            return Card(
              key: Key('foster_request_response_${response.id}'),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizedFosterResponseType(l, response.response),
                      style: theme.textTheme.labelMedium,
                    ),
                    if (response.message.isNotEmpty) Text(response.message),
                    if (response.earliestAvailability != null)
                      Text(
                        l.fosterRequestEarliestAvailability(
                          toCalendarDateString(response.earliestAvailability)!,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
