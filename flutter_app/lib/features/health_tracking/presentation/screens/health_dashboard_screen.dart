import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../pet_profile/data/services/pdf_saver.dart' as pdf_saver;
import '../../data/services/events_pdf_service.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/health_events_scope.dart';
import '../providers/health_providers.dart';
import '../widgets/health_dashboard_actions.dart'
    show HealthDashboardActions, GroupMode;
import '../widgets/health_dashboard/health_dashboard_entry_list.dart';
import '../widgets/health_dashboard/health_dashboard_org_filter.dart';
import '../widgets/health_dashboard/health_dashboard_pdf_groups.dart';

class HealthDashboardScreen extends ConsumerStatefulWidget {
  const HealthDashboardScreen({
    super.key,
    @visibleForTesting this.skipHeavyBody = false,
    this.embeddedInShell = false,
    this.scope = HealthEventsScope.all,
    this.backPath = '/',
  });

  /// When true, omits the [TabBarView] body so widget tests can assert the
  /// app bar / tab bar without spinning up six async entry lists (Linux CI
  /// segfault during flutter_tester teardown otherwise).
  @visibleForTesting
  final bool skipHeavyBody;

  /// When true, renders without [Scaffold] app bar (parent shell provides nav).
  final bool embeddedInShell;

  /// Limits which pets appear in lists and export filters.
  final HealthEventsScope scope;

  final String backPath;

  @override
  ConsumerState<HealthDashboardScreen> createState() =>
      _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends ConsumerState<HealthDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GroupMode _groupMode = GroupMode.dueDate;
  String? _orgFilter;

  static const _tabs = [
    null,
    HealthEntryType.medication,
    HealthEntryType.preventive,
    HealthEntryType.vetVisit,
    HealthEntryType.procedure,
    HealthEntryType.familyEvent,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final showOrgFilter =
        widget.scope == HealthEventsScope.all ||
        widget.scope == HealthEventsScope.organization;

    final body = widget.skipHeavyBody
        ? const SizedBox.shrink()
        : Column(
            children: [
              if (showOrgFilter)
                HealthDashboardOrgFilter(
                  selectedFilter: _orgFilter,
                  onFilterChanged: (filter) =>
                      setState(() => _orgFilter = filter),
                  scope: widget.scope,
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs
                      .map(
                        (type) => HealthDashboardEntryList(
                          type: type,
                          groupMode: _groupMode,
                          orgFilter: _effectiveOrgFilter(),
                          petIdFilter: _scopedPetIds(),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );

    final tabBar = TabBar(
      controller: _tabController,
      tabs: [
        Tab(key: const Key('health_tab_all'), text: l.all),
        Tab(key: const Key('health_tab_medications'), text: l.medications),
        Tab(key: const Key('health_tab_preventives'), text: l.preventives),
        Tab(key: const Key('health_tab_vet_visits'), text: l.vetVisits),
        Tab(key: const Key('health_tab_other'), text: l.other),
        Tab(key: const Key('health_tab_family'), text: l.careEvents),
      ],
      isScrollable: true,
    );

    final fab = FloatingActionButton.extended(
      key: const Key('add_health_entry_button'),
      tooltip: l.addHealthEntry,
      onPressed: () {
        final tabIndex = _tabController.index;
        final type = tabIndex < _tabs.length ? _tabs[tabIndex] : null;
        if (type != null) {
          context.go('/health/add?type=${type.name}');
        } else {
          context.go('/health/add');
        }
      },
      icon: const Icon(Icons.add),
      label: Text(l.addEntry),
    );

    if (widget.embeddedInShell) {
      return Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Expanded(child: tabBar),
                HealthDashboardActions(
                  onExportPdf: _exportPdf,
                  onExportCsv: _exportCsv,
                  onGroupModeChanged: (mode) => setState(() => _groupMode = mode),
                  groupMode: _groupMode,
                  lGroupBy: l.groupBy,
                  lByDueDate: l.byDueDate,
                  lByPet: l.byPet,
                  lBySpecies: l.bySpecies,
                  lExportPdf: l.exportPdf,
                  lExportCsv: l.exportCsv,
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: l.events),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l.goBack,
          onPressed: () => context.go(widget.backPath),
        ),
        actions: [
          HealthDashboardActions(
            onExportPdf: _exportPdf,
            onExportCsv: _exportCsv,
            onGroupModeChanged: (mode) => setState(() => _groupMode = mode),
            groupMode: _groupMode,
            lGroupBy: l.groupBy,
            lByDueDate: l.byDueDate,
            lByPet: l.byPet,
            lBySpecies: l.bySpecies,
            lExportPdf: l.exportPdf,
            lExportCsv: l.exportCsv,
          ),
        ],
        bottom: tabBar,
      ),
      body: body,
      floatingActionButton: fab,
    );
  }

  Set<String>? _scopedPetIds() {
    final pets = ref.read(petListProvider).valueOrNull ?? [];
    if (widget.scope == HealthEventsScope.all) return null;
    if (widget.scope == HealthEventsScope.guardian) {
      final controller = PetListController();
      return controller.guardianShellPets(pets).map((p) => p.id).toSet();
    }
    final controller = PetListController();
    return controller.orgShellPets(pets).map((p) => p.id).toSet();
  }

  String? _effectiveOrgFilter() {
    if (widget.scope == HealthEventsScope.organization) return _orgFilter;
    return widget.scope == HealthEventsScope.all ? _orgFilter : null;
  }

  Future<void> _exportCsv() async {
    final l = AppLocalizations.of(context)!;
    try {
      final csv = await ref.read(healthRepositoryProvider).exportCsv();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.csvExport),
          content: SingleChildScrollView(
            child: SelectableText(csv, style: const TextStyle(fontSize: 12)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.close),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.exportFailed(e.toString()))));
    }
  }

  Future<void> _exportPdf() async {
    final l = AppLocalizations.of(context)!;
    try {
      final tabIndex = _tabController.index;
      final typeFilter = tabIndex < _tabs.length ? _tabs[tabIndex] : null;

      final entriesAsync = ref.read(filteredHealthEntriesProvider(typeFilter));
      final petsAsync = ref.read(petListProvider);
      var entries = entriesAsync.valueOrNull ?? [];
      final pets = petsAsync.valueOrNull ?? <Pet>[];
      final petMap = {for (final p in pets) p.id: p};

      if (_orgFilter != null) {
        final filteredPetIds = _orgFilter == '_personal'
            ? pets
                  .where((p) => p.organizationId == null)
                  .map((p) => p.id)
                  .toSet()
            : pets
                  .where((p) => p.organizationName == _orgFilter)
                  .map((p) => p.id)
                  .toSet();
        entries = entries
            .where((e) => filteredPetIds.contains(e.petId))
            .toList();
      }

      final groups = buildEventsPdfGroups(
        entries: entries,
        petMap: petMap,
        mode: _groupMode,
        l: l,
      );

      final filterLabel = typeFilter == null ? l.all : typeFilter.label;
      final groupLabel = switch (_groupMode) {
        GroupMode.dueDate => l.byDueDate,
        GroupMode.pet => l.byPet,
        GroupMode.petType => l.bySpecies,
      };

      final bytes = await EventsPdfService().generate(
        groups: groups,
        petMap: petMap,
        filterLabel: filterLabel,
        groupLabel: groupLabel,
        l: l,
      );

      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      await pdf_saver.savePdf(bytes, 'Events_${dateStr}.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.pdfExportFailed(e.toString()))));
    }
  }
}
