import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/shell_return_navigation.dart';
import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../away_planning_dashboard_tile_state.dart';
import '../away_planning_tile_copy.dart';
import '../providers/care_context_providers.dart';

class PlannedAbsenceEntryTile extends ConsumerWidget {
  const PlannedAbsenceEntryTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tileAsync = ref.watch(awayPlanningDashboardTileProvider);
    final l = AppLocalizations.of(context)!;
    return tileAsync.when(
      loading: () => _card(
        l.careContextAwayEntryTitle,
        l.careContextAwayEntryBody,
        () => context.push('/pc/away'),
      ),
      error: (_, __) => _card(
        l.careContextAwayEntryTitle,
        l.careContextAwayEntryBody,
        () => context.push('/pc/away'),
      ),
      data: (s) {
        if (s.mode == AwayPlanningDashboardTileMode.stateful &&
            s.absence != null &&
            s.tileCopy != null) {
          final a = s.absence!;
          final body = AwayPlanningTileCopy.resolve(l, s.tileCopy!);
          final st = parseCalendarDate(a.startsOn);
          final en = parseCalendarDate(a.endsOn);
          final title = st != null && en != null
              ? l.careContextAwayPreviewDateRange(
                  formatCalendarDateDisplay(st),
                  formatCalendarDateDisplay(en),
                )
              : l.careContextAwayEntryTitle;
          return _card(title, body, () => openAwayPlanDetail(context, a.id));
        }
        return _card(
          l.careContextAwayEntryTitle,
          l.careContextAwayEntryBody,
          () => context.push('/pc/away'),
        );
      },
    );
  }

  Widget _card(String title, String body, VoidCallback onTap) => Card(
    margin: EdgeInsets.zero,
    child: Semantics(
      button: true,
      identifier: 'planned_absence_entry_tile',
      label: '$title. $body',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        key: const Key('planned_absence_entry_tile'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColorTokens.petCareLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.event_busy_outlined,
                    color: AppColorTokens.petCareCarePrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(body),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    ),
  );
}
