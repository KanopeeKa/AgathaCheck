import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../providers/org_provider_deps.dart';
import '../../providers/org_provider_pets.dart';
import '../../widgets/org_shell_app_bar_title.dart';
import '../../widgets/org_shell_scaffold.dart';

class AdoptionVisitsScreen extends ConsumerStatefulWidget {
  const AdoptionVisitsScreen({super.key, required this.orgId});

  final String orgId;

  @override
  ConsumerState<AdoptionVisitsScreen> createState() =>
      _AdoptionVisitsScreenState();
}

class _AdoptionVisitsScreenState extends ConsumerState<AdoptionVisitsScreen> {
  late Future<List<Map<String, dynamic>>> _visitsFuture;
  var _busyVisitId = '';

  @override
  void initState() {
    super.initState();
    _visitsFuture = _loadVisits();
  }

  Future<List<Map<String, dynamic>>> _loadVisits() {
    final token = ref.read(orgTokenProvider);
    if (token == null) return Future.value(const []);
    return ref
        .read(organizationRepositoryProvider)
        .getAdoptionVisits(widget.orgId, token);
  }

  Future<void> _reloadVisits() async {
    setState(() => _visitsFuture = _loadVisits());
    await _visitsFuture;
  }

  Future<void> _recordOutcome(String visitId, String outcome) async {
    final token = ref.read(orgTokenProvider);
    if (token == null) return;
    setState(() => _busyVisitId = visitId);
    try {
      await ref
          .read(organizationRepositoryProvider)
          .recordAdoptionVisitOutcome(widget.orgId, visitId, outcome, token);
      await _reloadVisits();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.adoptionVisitOutcomeSaved,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busyVisitId = '');
    }
  }

  String _outcomeLabel(AppLocalizations l, String? outcome) {
    switch (outcome) {
      case 'positive':
        return l.adoptionVisitOutcomePositive;
      case 'negative':
        return l.adoptionVisitOutcomeNegative;
      case 'no_show':
        return l.adoptionVisitOutcomeNoShow;
      default:
        return l.adoptionVisitOutcomePending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = ref.watch(orgTokenProvider);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final isAdmin = ref.watch(isOrgAdminProvider(widget.orgId));
    return OrgShellScaffold(
  title: l.adoptionVisitsTitle,
  orgId: widget.orgId,
  navVariant: OrgNavTitleVariant.withOrgLogo,
  child: FutureBuilder<List<Map<String, dynamic>>>(
          future: token == null ? Future.value(const []) : _visitsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            }
            final visits = snapshot.data ?? const [];
            if (visits.isEmpty) {
              return Center(
                child: Text(
                  l.adoptionVisitsEmpty,
                  style: theme.textTheme.bodyMedium,
                ),
              );
            }
            return ListView.separated(
              itemCount: visits.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final visit = visits[index];
                final visitId = visit['id']?.toString() ?? '';
                final visitOutcome = visit['visit_outcome']?.toString();
                final busy = _busyVisitId == visitId;
                return ListTile(
                  key: Key('adoption_visit_$visitId'),
                  title: Text(visit['scheduled_at']?.toString() ?? ''),
                  subtitle: Text(
                    '${visit['status']} · ${_outcomeLabel(l, visitOutcome)}',
                  ),
                  trailing:
                      isAdmin &&
                          visitOutcome == null &&
                          visit['status'] != 'cancelled' &&
                          !busy
                      ? Wrap(
                          spacing: 4,
                          children: [
                            TextButton(
                              key: Key('adoption_visit_${visitId}_positive'),
                              onPressed: () =>
                                  _recordOutcome(visitId, 'positive'),
                              child: Text(l.adoptionVisitOutcomePositive),
                            ),
                            TextButton(
                              key: Key('adoption_visit_${visitId}_negative'),
                              onPressed: () =>
                                  _recordOutcome(visitId, 'negative'),
                              child: Text(l.adoptionVisitOutcomeNegative),
                            ),
                            TextButton(
                              key: Key('adoption_visit_${visitId}_no_show'),
                              onPressed: () =>
                                  _recordOutcome(visitId, 'no_show'),
                              child: Text(l.adoptionVisitOutcomeNoShow),
                            ),
                          ],
                        )
                      : busy
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                );
              },
            );
          },
    ),
    );
  }
}
