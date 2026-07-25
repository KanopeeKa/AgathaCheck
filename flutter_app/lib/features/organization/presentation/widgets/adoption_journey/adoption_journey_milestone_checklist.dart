import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../providers/org_provider_deps.dart';
import '../../providers/org_provider_pets.dart';

class AdoptionJourneyMilestoneChecklist extends ConsumerStatefulWidget {
  const AdoptionJourneyMilestoneChecklist({
    super.key,
    required this.orgId,
    required this.placementId,
  });

  final String orgId;
  final String placementId;

  @override
  ConsumerState<AdoptionJourneyMilestoneChecklist> createState() =>
      _AdoptionJourneyMilestoneChecklistState();
}

class _AdoptionJourneyMilestoneChecklistState
    extends ConsumerState<AdoptionJourneyMilestoneChecklist> {
  late Future<Map<String, dynamic>> _milestonesFuture;
  var _busyKey = '';

  @override
  void initState() {
    super.initState();
    _milestonesFuture = _loadMilestones();
  }

  Future<Map<String, dynamic>> _loadMilestones() {
    final token = ref.read(orgTokenProvider);
    if (token == null) {
      return Future.error(StateError('Not authenticated'));
    }
    return ref
        .read(organizationRepositoryProvider)
        .getAdoptionMilestones(widget.orgId, widget.placementId, token);
  }

  Future<void> _reloadMilestones() async {
    setState(() => _milestonesFuture = _loadMilestones());
    await _milestonesFuture;
  }

  Future<void> _toggleItem(
    String journeyId,
    String itemKey,
    bool completed,
  ) async {
    final token = ref.read(orgTokenProvider);
    if (token == null) return;
    setState(() => _busyKey = itemKey);
    try {
      await ref
          .read(organizationRepositoryProvider)
          .updateAdoptionMilestoneItem(
            widget.orgId,
            journeyId,
            itemKey,
            completed: completed,
            token: token,
          );
      await _reloadMilestones();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busyKey = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdmin = ref.watch(isOrgAdminProvider(widget.orgId));

    return FutureBuilder<Map<String, dynamic>>(
      future: _milestonesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        final data = snapshot.data ?? {};
        final journeyId = data['journey_id']?.toString() ?? '';
        final items = (data['items'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.adoptionJourneyMilestonesTitle,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(
                l.adoptionJourneyMilestonesEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...items.map((item) {
                final key = item['key']?.toString() ?? '';
                final label = item['label']?.toString() ?? key;
                final completed = item['completed'] == true;
                final busy = _busyKey == key;
                return CheckboxListTile(
                  key: Key('adoption_milestone_item_$key'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: completed,
                  onChanged: isAdmin && journeyId.isNotEmpty && !busy
                      ? (value) => _toggleItem(journeyId, key, value == true)
                      : null,
                  title: Text(label),
                );
              }),
          ],
        );
      },
    );
  }
}
