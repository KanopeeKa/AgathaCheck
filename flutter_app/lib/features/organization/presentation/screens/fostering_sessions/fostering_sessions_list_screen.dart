import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/app_logo_title.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../providers/fostering_sessions_providers.dart';
import '../../utils/org_screen_theme.dart';
import '../../widgets/fostering_sessions/fostering_session_list_tile.dart';

class FosteringSessionsListScreen extends ConsumerStatefulWidget {
  const FosteringSessionsListScreen({super.key, required this.orgId});

  final String orgId;

  @override
  ConsumerState<FosteringSessionsListScreen> createState() =>
      _FosteringSessionsListScreenState();
}

class _FosteringSessionsListScreenState
    extends ConsumerState<FosteringSessionsListScreen> {
  late final TextEditingController _petNameController;
  late final TextEditingController _fosterNameController;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(fosteringSessionsFiltersProvider(widget.orgId));
    _petNameController = TextEditingController(text: filters['pet_name'] ?? '');
    _fosterNameController = TextEditingController(
      text: filters['foster_name'] ?? '',
    );
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _fosterNameController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final nextFilters = <String, String>{};
    final petName = _petNameController.text.trim();
    final fosterName = _fosterNameController.text.trim();
    if (petName.isNotEmpty) nextFilters['pet_name'] = petName;
    if (fosterName.isNotEmpty) nextFilters['foster_name'] = fosterName;
    ref.read(fosteringSessionsFiltersProvider(widget.orgId).notifier).state =
        nextFilters;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sessionsAsync = ref.watch(
      fosteringSessionsListProvider(widget.orgId),
    );

    return orgThemed(
      child: Scaffold(
        key: const Key('fostering_sessions_list_screen'),
        appBar: AppBar(
          title: AppLogoTitle(title: l.orgFosteringSessionsListTitle),
          leading: IconButton(
            key: const Key('fostering_sessions_back'),
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => context.pop(),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                l.fosteringSessionPreparationPlaceholder,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('fostering_sessions_filter_pet_name'),
                      controller: _petNameController,
                      decoration: InputDecoration(
                        labelText: l.orgPetsFilterName,
                        hintText: l.orgPetsFilterNameHint,
                      ),
                      onSubmitted: (_) => _applyFilters(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      key: const Key('fostering_sessions_filter_foster_name'),
                      controller: _fosterNameController,
                      decoration: InputDecoration(
                        labelText: l.orgPetsFilterFosteredBy,
                        hintText: l.orgPetsFilterFosteredByHint,
                      ),
                      onSubmitted: (_) => _applyFilters(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const Key('fostering_sessions_apply_filters'),
                    tooltip: l.orgPetsFiltersLabel,
                    onPressed: _applyFilters,
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
            Expanded(
              child: sessionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Center(child: Text(l.orgFosteringSessionsEmpty));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final placement = sessions[index];
                      return FosteringSessionListTile(
                        placement: placement,
                        onTap: () => context.push(
                          '/o/orgs/${widget.orgId}/placements/${placement.id}/session',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
