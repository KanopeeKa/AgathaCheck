import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../providers/org_provider_deps.dart';
import '../../providers/org_provider_pets.dart';

class FosteringSessionPreparationChecklist extends ConsumerStatefulWidget {
  const FosteringSessionPreparationChecklist({
    super.key,
    required this.orgId,
    required this.placementId,
  });

  final String orgId;
  final String placementId;

  @override
  ConsumerState<FosteringSessionPreparationChecklist> createState() =>
      _FosteringSessionPreparationChecklistState();
}

class _FosteringSessionPreparationChecklistState
    extends ConsumerState<FosteringSessionPreparationChecklist> {
  late Future<Map<String, dynamic>> _checklistFuture;
  var _busyKey = '';

  @override
  void initState() {
    super.initState();
    _checklistFuture = _loadChecklist();
  }

  Future<Map<String, dynamic>> _loadChecklist() {
    final token = ref.read(orgTokenProvider);
    if (token == null) {
      return Future.error(StateError('Not authenticated'));
    }
    return ref
        .read(organizationRepositoryProvider)
        .getSessionChecklist(widget.orgId, widget.placementId, token);
  }

  Future<void> _reloadChecklist() async {
    setState(() => _checklistFuture = _loadChecklist());
    await _checklistFuture;
  }

  Future<void> _toggleItem(String itemKey, bool completed) async {
    final token = ref.read(orgTokenProvider);
    if (token == null) return;
    setState(() => _busyKey = itemKey);
    try {
      await ref
          .read(organizationRepositoryProvider)
          .updateSessionChecklistItem(
            widget.orgId,
            widget.placementId,
            itemKey,
            completed: completed,
            token: token,
          );
      await _reloadChecklist();
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

    return Card(
      key: const Key('fostering_session_preparation_checklist'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _checklistFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.fosteringSessionPreparationTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator()),
                ],
              );
            }
            if (snapshot.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.fosteringSessionPreparationTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}'),
                ],
              );
            }
            final items =
                (snapshot.data?['items'] as List<dynamic>? ?? const [])
                    .cast<Map<String, dynamic>>();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.fosteringSessionPreparationTitle,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  l.fosteringSessionChecklistDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  Text(
                    l.fosteringSessionChecklistEmpty,
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
                      key: Key('session_checklist_item_$key'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: completed,
                      onChanged: isAdmin && !busy
                          ? (value) => _toggleItem(key, value == true)
                          : null,
                      title: Text(label),
                      subtitle: item['is_required'] == true
                          ? Text(
                              l.fosteringSessionChecklistRequired,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}
