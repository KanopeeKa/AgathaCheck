import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/services/pdf_saver.dart' as pdf_saver;
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/domain/entities/app_notification.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/domain/entities/health_issue.dart';
import '../../../health_tracking/presentation/providers/health_issue_providers.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../health_tracking/presentation/widgets/health_entry_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../organization/domain/entities/family_event.dart';
import '../../../organization/domain/entities/organization_member.dart';
import '../../../organization/presentation/providers/organization_providers.dart';
import '../../../sharing/domain/entities/pet_access.dart';
import '../../../sharing/presentation/providers/sharing_providers.dart';
import '../../../vet/presentation/providers/vet_providers.dart';
import '../../../weight_tracking/domain/entities/weight_entry.dart';
import '../../../weight_tracking/presentation/providers/weight_providers.dart';
import '../../data/models/pet_model.dart';
import '../../data/services/pet_report_service.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_providers.dart';

class PetDetailScreen extends ConsumerStatefulWidget {
  const PetDetailScreen({super.key, required this.petId});

  final String petId;

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {

  @override
  Widget build(BuildContext context) {
    final petListAsync = ref.watch(petListProvider);
    final l = AppLocalizations.of(context)!;

    return petListAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: AppLogoTitle(title: l.petDetails)),
        body: Center(child: Text(l.errorWithMessage(error.toString()))),
      ),
      data: (pets) {
        final pet = pets.where((p) => p.id == widget.petId).firstOrNull;
        if (pet == null) {
          return Scaffold(
            appBar: AppBar(title: AppLogoTitle(title: l.petDetails)),
            body: Center(child: Text(l.petNotFound)),
          );
        }

        final auth = ref.watch(authProvider);
        final theme = Theme.of(context);
        final unreadCount = ref.watch(unreadNotificationCountProvider);
        final isOrgPet = pet.organizationId != null;

        Widget body = Scaffold(
          backgroundColor: isOrgPet ? AppTheme.orgBlue : null,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: isOrgPet ? AppTheme.orgBlue : null,
                title: AppLogoTitle(title: pet.name),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: l.goBack,
                  onPressed: () => context.go('/'),
                ),
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        tooltip: l.notifications,
                        onPressed: () => context.go('/notifications'),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.local_hospital),
                    tooltip: l.veterinarians,
                    onPressed: () => context.go('/vets'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.list_alt),
                    tooltip: l.events,
                    onPressed: () => context.go('/health'),
                  ),
                  PopupMenuButton<String>(
                    tooltip: l.userMenu,
                    icon: CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        ((auth.user?.firstName?.isNotEmpty == true)
                          ? auth.user!.firstName![0]
                          : (auth.user?.lastName?.isNotEmpty == true ? auth.user!.lastName![0] : auth.user?.email[0] ?? 'U'))
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    onSelected: (value) async {
                      if (value == 'details') {
                        context.push('/my-details');
                      } else if (value == 'logout') {
                        await ref.read(authProvider.notifier).logout();
                      }
                    },
                    itemBuilder: (context) {
                      final l = AppLocalizations.of(context)!;
                      return [
                        PopupMenuItem<String>(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.user?.firstName?.isNotEmpty == true
                                  ? auth.user!.firstName!
                                  : (auth.user?.lastName?.isNotEmpty == true ? auth.user!.lastName! : 'User'),
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                auth.user?.email ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'details',
                          child: ListTile(
                            leading: const Icon(Icons.person_outlined),
                            title: Text(l.myDetails),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: ListTile(
                            leading: const Icon(Icons.logout),
                            title: Text(l.logOut),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: MergeSemantics(
                  child: _PetProfileCard(pet: pet),
                ),
              ),
              if (pet.neuteredDate == null && !pet.neuterDismissed && !AppConstants.speciesWithoutNeutering.contains(pet.species))
                SliverToBoxAdapter(
                  child: _NeuterReminderCard(pet: pet),
                ),
              if (pet.chipId.isEmpty && !pet.chipDismissed)
                SliverToBoxAdapter(
                  child: _ChipReminderCard(pet: pet),
                ),
              SliverToBoxAdapter(
                child: WeightTrackingSection(petId: widget.petId),
              ),
              SliverToBoxAdapter(
                child: HealthEventsSection(petId: widget.petId, pet: pet),
              ),
              SliverToBoxAdapter(
                child: HealthIssuesSection(petId: widget.petId, pet: pet),
              ),
              if (pet.organizationId != null)
                SliverToBoxAdapter(
                  child: FamilyEventsSection(petId: widget.petId, pet: pet),
                ),
              SliverToBoxAdapter(
                child: SharingSection(petId: widget.petId, pet: pet),
              ),
              SliverToBoxAdapter(
                child: DownloadReportSection(pet: pet),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        );

        if (isOrgPet) {
          body = Theme(
            data: theme.copyWith(
              cardTheme: theme.cardTheme.copyWith(
                color: AppTheme.orgBlueDarker,
              ),
            ),
            child: body,
          );
        }

        return body;
      },
    );
  }
}

class _PetProfileCard extends ConsumerWidget {
  const _PetProfileCard({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final vetsAsync = ref.watch(vetListProvider);
    final vets = vetsAsync.valueOrNull ?? [];
    final assignedVet = (pet.vetId != null && pet.vetId!.isNotEmpty)
        ? vets.where((v) => v.id == pet.vetId).firstOrNull
        : null;

    final latestWeightAsync = ref.watch(latestWeightProvider(pet.id));
    final latestWeight = latestWeightAsync.valueOrNull;
    final displayWeight = latestWeight?.weight ?? pet.weight;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 140,
                child: _PetPhoto(pet: pet),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(pet.name,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            key: const Key('edit_pet_button'),
                            icon: Icon(Icons.edit,
                                size: 20, color: colorScheme.primary),
                            tooltip: AppLocalizations.of(context)!.editPet,
                            onPressed: () => context.go('/edit/${pet.id}'),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChipWidget(iconWidget: AppConstants.speciesIconWidget(pet.species, size: 18), label: pet.species),
                          if (pet.breed.isNotEmpty)
                            _InfoChip(icon: Icons.pets, label: pet.breed),
                          if (pet.gender != null && pet.gender!.isNotEmpty)
                            _InfoChip(
                                icon: pet.gender == 'Male'
                                    ? Icons.male
                                    : Icons.female,
                                label: pet.gender!),
                          if (pet.ageDisplay != null)
                            _InfoChip(
                                icon: Icons.cake,
                                label: pet.ageDisplay!),
                          if (displayWeight != null)
                            Consumer(builder: (context, ref, _) {
                              final unit =
                                  ref.watch(weightUnitProvider(pet.id));
                              final converted =
                                  convertWeight(displayWeight, unit);
                              return _InfoChip(
                                  icon: Icons.monitor_weight,
                                  label:
                                      '${converted.toStringAsFixed(1)} ${weightUnitLabel(unit)}');
                            }),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildVetRow(context, ref, assignedVet, vets,
                          theme, colorScheme),
                      if (pet.bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(pet.bio,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
                      ],
                      if (pet.neuteredDate != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.check_circle, size: 18,
                                color: Colors.green),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.neuteredSpayed(DateFormat.yMMMd().format(pet.neuteredDate!)),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ],
                      if (pet.chipId.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.memory, size: 18,
                                color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.idLabel(pet.chipId),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ],
                      if (pet.insurance.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.shield, size: 18,
                                color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppLocalizations.of(context)!.insuranceDetails,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(pet.insurance,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              color: colorScheme
                                                  .onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVetRow(BuildContext context, WidgetRef ref, dynamic assignedVet,
      List vets, ThemeData theme, ColorScheme colorScheme) {
    final l = AppLocalizations.of(context)!;
    if (vets.isEmpty) {
      return Semantics(
        label: l.addVetFirst,
        button: true,
        child: GestureDetector(
        onTap: () => GoRouter.of(context).go('/vets/add'),
        child: Row(
          children: [
            Icon(Icons.local_hospital, size: 16,
                color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(l.noVetAssigned,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant)),
            const SizedBox(width: 4),
            Text('— Add one',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      );
    }

    return Row(
      children: [
        Icon(Icons.local_hospital, size: 16,
            color: assignedVet != null
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: PopupMenuButton<String?>(
            tooltip: l.selectVeterinarian,
            padding: EdgeInsets.zero,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  assignedVet != null ? assignedVet.name : l.noVetAssigned,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: assignedVet != null
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: assignedVet != null
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 20,
                    color: colorScheme.onSurfaceVariant),
              ],
            ),
            onSelected: (vetId) async {
              final updated = vetId == null
                  ? pet.copyWith(clearVetId: true)
                  : pet.copyWith(vetId: vetId);
              await ref.read(petListProvider.notifier).updatePet(updated);
            },
            itemBuilder: (context) => [
              if (assignedVet != null)
                PopupMenuItem<String?>(
                  value: null,
                  child: Text(l.removeVet),
                ),
              ...vets.map((vet) => PopupMenuItem<String?>(
                    value: vet.id,
                    enabled: assignedVet?.id != vet.id,
                    child: Text(vet.name),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeightTrackingSection extends ConsumerWidget {
  const _WeightTrackingSection({required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(weightEntriesNotifierProvider(petId));
    final unit = ref.watch(weightUnitProvider(petId));
    final unitLabel = unit == WeightUnit.lb ? 'lb' : 'kg';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: Icon(Icons.monitor_weight, color: colorScheme.primary),
          title: Text(l.weightTracking,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SegmentedButton<WeightUnit>(
                    segments: const [
                      ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                      ButtonSegment(value: WeightUnit.lb, label: Text('lb')),
                    ],
                    selected: {unit},
                    onSelectionChanged: (sel) => ref
                        .read(weightUnitProvider(petId).notifier)
                        .setUnit(sel.first),
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: l.addWeightEntry,
                    child: FilledButton.tonalIcon(
                      onPressed: () =>
                          _showAddWeightSheet(context, ref, unit, unitLabel),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l.addEntry),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            entriesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.errorLoadingWeightData(error.toString()),
                    style: TextStyle(color: colorScheme.error)),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.scale_outlined, size: 48,
                            color: colorScheme.outline),
                        const SizedBox(height: 8),
                        Text(l.noWeightDataYet,
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(l.tapAddEntryToStart,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.outline)),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    if (entries.length >= 2)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 200,
                          child:
                              _WeightChart(entries: entries, unit: unit),
                        ),
                      ),
                    if (entries.length >= 2) const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = entries[entries.length - 1 - index];
                        return _WeightEntryTile(
                          entry: entry,
                          unit: unit,
                          onDelete: () async {
                            await ref
                                .read(weightEntriesNotifierProvider(petId)
                                    .notifier)
                                .deleteEntry(entry.id);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWeightSheet(
      BuildContext context, WidgetRef ref, WeightUnit unit, String unitLabel) {
    final weightController = TextEditingController();
    final notesController = TextEditingController();
    var selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final theme = Theme.of(ctx);
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AppLocalizations.of(ctx)!.addWeightEntry,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Semantics(
                  label: 'Select date for weight entry',
                  button: true,
                  child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(ctx)!.date,
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: const OutlineInputBorder(),
                    ),
                    child: Text(DateFormat.yMMMd().format(selectedDate)),
                  ),
                ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(ctx)!.weightWithUnit(unitLabel),
                    prefixIcon: const Icon(Icons.monitor_weight),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(ctx)!.notesOptional,
                    prefixIcon: const Icon(Icons.notes),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    final weightText = weightController.text.trim();
                    if (weightText.isEmpty) return;
                    final inputWeight = double.tryParse(weightText);
                    if (inputWeight == null || inputWeight <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a valid weight')),
                      );
                      return;
                    }

                    final weightInKg = convertToKg(inputWeight, unit);

                    final entry = WeightEntry(
                      id: 0,
                      petId: petId,
                      date: selectedDate,
                      weight: weightInKg,
                      notes: notesController.text.trim(),
                    );

                    await ref
                        .read(
                            weightEntriesNotifierProvider(petId).notifier)
                        .addEntry(entry);

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(AppLocalizations.of(ctx)!.save),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WeightEntryTile extends StatelessWidget {
  const _WeightEntryTile(
      {required this.entry, required this.onDelete, required this.unit});

  final WeightEntry entry;
  final VoidCallback onDelete;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayWeight = convertWeight(entry.weight, unit);
    final label = weightUnitLabel(unit);

    return MergeSemantics(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.monitor_weight, size: 20,
              color: colorScheme.onPrimaryContainer),
        ),
        title: Text('${displayWeight.toStringAsFixed(1)} $label',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          DateFormat.yMMMd().format(entry.date) +
              (entry.notes.isNotEmpty ? ' — ${entry.notes}' : ''),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
          tooltip: AppLocalizations.of(context)!.deleteWeightEntry,
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.entries, required this.unit});

  final List<WeightEntry> entries;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final label = weightUnitLabel(unit);

    final sorted = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final weights = sorted.map((e) => convertWeight(e.weight, unit)).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;
    final yMin = (minWeight - (range * 0.2)).clamp(0.0, double.infinity);
    final yMax = maxWeight + (range * 0.2);
    final effectiveYMin = range < 0.1 ? minWeight - 1 : yMin;
    final effectiveYMax = range < 0.1 ? maxWeight + 1 : yMax;

    final firstDate = sorted.first.date;

    final spots = List.generate(sorted.length, (i) {
      final x = sorted[i].date.difference(firstDate).inDays.toDouble();
      return FlSpot(x, weights[i]);
    });

    return Semantics(
      label: AppLocalizations.of(context)!.weightChartLabel(entries.length),
      child: LineChart(
      LineChartData(
        minY: effectiveYMin,
        maxY: effectiveYMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: range < 0.1 ? 0.5 : null,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant.withAlpha(80),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Text('${value.toStringAsFixed(1)} $label',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final date =
                    firstDate.add(Duration(days: value.toInt()));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(DateFormat('M/d').format(date),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date =
                    firstDate.add(Duration(days: spot.x.toInt()));
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} $label\n${DateFormat.yMMMd().format(date)}',
                  TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: colorScheme.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: colorScheme.primary,
                strokeWidth: 2,
                strokeColor: colorScheme.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withAlpha(30),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _PetPhoto extends StatelessWidget {
  const _PetPhoto({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final petColor = pet.colorValue != null
        ? Color(pet.colorValue!)
        : colorScheme.primary;

    Widget photoContent;

    if (pet.photoPath != null && pet.photoPath!.isNotEmpty) {
      try {
        final bytes = base64Decode(pet.photoPath!);
        photoContent = Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: petColor, width: 5)),
          ),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            semanticLabel: 'Photo of ${pet.name}',
          ),
        );
      } catch (_) {
        photoContent = _buildPlaceholder(petColor);
      }
    } else {
      photoContent = _buildPlaceholder(petColor);
    }

    if (pet.passedAway) {
      return ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xDDFFFFFF),
                BlendMode.lighten,
              ),
              child: photoContent,
            ),
            Center(
              child: Opacity(
                opacity: 0.35,
                child: Image.asset(
                  'assets/rainbow_wings.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return photoContent;
  }

  Widget _buildPlaceholder(Color petColor) {
    return Container(
      decoration: BoxDecoration(
        color: petColor.withValues(alpha: 0.12),
        border: Border(left: BorderSide(color: petColor, width: 5)),
      ),
      child: Center(
        child: AppConstants.speciesIconWidget(pet.species, size: 56, color: petColor.withValues(alpha: 0.6)),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _InfoChipWidget extends StatelessWidget {
  const _InfoChipWidget({required this.iconWidget, required this.label});

  final Widget iconWidget;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _FamilyEventsSection extends ConsumerWidget {
  const _FamilyEventsSection({required this.petId, required this.pet});

  final String petId;
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(familyEventsProvider(petId));
    final membersAsync = pet.organizationId != null
        ? ref.watch(orgMembersProvider(pet.organizationId!))
        : const AsyncValue<List<OrganizationMember>>.data([]);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final dateFormat = DateFormat.yMMMd();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: ExpansionTile(
          key: const Key('family_events_section'),
          leading: Icon(Icons.family_restroom, size: 20, color: colorScheme.primary),
          title: Text(l.familyEvents,
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  eventsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text('$e',
                        style: TextStyle(color: colorScheme.error)),
                    data: (events) {
                      if (events.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(l.noFamilyEvents,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant)),
                        );
                      }
                      return Column(
                        children: events.map((event) => Dismissible(
                          key: Key('family_event_${event.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            color: colorScheme.error,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l.delete),
                                content: Text(l.deleteFamilyEventConfirm),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(l.cancel),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: colorScheme.error),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(l.delete),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) {
                            ref.read(familyEventsProvider(petId).notifier)
                                .deleteEvent(event.id);
                          },
                          child: Card(
                            color: colorScheme.surfaceContainerHighest.withAlpha(80),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showEditFamilyEventDialog(
                                  context, ref, event, membersAsync, l),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (event.assignedDisplay.isNotEmpty)
                                      Row(
                                        children: [
                                          Icon(Icons.person, size: 16,
                                              color: colorScheme.primary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(event.assignedDisplay,
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w600)),
                                          ),
                                          Icon(Icons.edit, size: 14,
                                              color: colorScheme.onSurfaceVariant),
                                        ],
                                      ),
                                    if (event.assignedDisplay.isEmpty)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Icon(Icons.edit, size: 14,
                                            color: colorScheme.onSurfaceVariant),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 14,
                                            color: colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 6),
                                        Text(
                                          dateFormat.format(event.fromDate),
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        if (event.toDate != null) ...[
                                          Text(' — ',
                                              style: theme.textTheme.bodySmall),
                                          Text(
                                            dateFormat.format(event.toDate!),
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (event.notes.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(event.notes,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('add_family_event_button'),
                    onPressed: () => _showAddFamilyEventDialog(
                        context, ref, membersAsync, l),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l.addFamilyEvent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFamilyEventDialog(BuildContext context, WidgetRef ref,
      FamilyEvent event,
      AsyncValue<List<OrganizationMember>> membersAsync, AppLocalizations l) {
    final notesController = TextEditingController(text: event.notes);
    int? selectedMemberId = event.assignedToUserId;
    DateTime fromDate = event.fromDate;
    DateTime? toDate = event.toDate;
    final dateFormat = DateFormat.yMMMd();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final members = membersAsync.valueOrNull ?? <OrganizationMember>[];

          return AlertDialog(
            title: Text(l.editFamilyEvent),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.assignedToMember,
                      style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: members.any((m) => m.userId == selectedMemberId)
                        ? selectedMemberId
                        : null,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(l.unassigned),
                      ),
                      ...members.map((m) {
                        return DropdownMenuItem<int?>(
                          value: m.userId,
                          child: Text(m.displayName.isNotEmpty
                              ? m.displayName
                              : m.email),
                        );
                      }),
                    ],
                    onChanged: (v) => setState(() => selectedMemberId = v),
                  ),
                  const SizedBox(height: 16),
                  Text(l.fromDateLabel,
                      style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: fromDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => fromDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(dateFormat.format(fromDate)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('${l.toDateLabel} (${l.optional})',
                      style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: toDate ?? fromDate,
                        firstDate: fromDate,
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => toDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixIcon: toDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setState(() => toDate = null),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(toDate != null
                          ? dateFormat.format(toDate!)
                          : l.notSet),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: l.notes,
                      prefixIcon: const Icon(Icons.notes),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await ref
                        .read(familyEventsProvider(petId).notifier)
                        .updateEvent(
                          event.id,
                          assignedToUserId: selectedMemberId,
                          fromDate: fromDate,
                          toDate: toDate,
                          notes: notesController.text.trim(),
                        );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    }
                  }
                },
                child: Text(l.save),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddFamilyEventDialog(BuildContext context, WidgetRef ref,
      AsyncValue<List<OrganizationMember>> membersAsync, AppLocalizations l) {
    final notesController = TextEditingController();
    int? selectedMemberId;
    DateTime fromDate = DateTime.now();
    DateTime? toDate;
    final dateFormat = DateFormat.yMMMd();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final members = membersAsync.valueOrNull ?? <OrganizationMember>[];

          return AlertDialog(
            title: Text(l.addFamilyEvent),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.assignedToMember,
                      style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: selectedMemberId,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(l.unassigned),
                      ),
                      ...members.map((m) {
                        return DropdownMenuItem<int?>(
                          value: m.userId,
                          child: Text(m.displayName.isNotEmpty
                              ? m.displayName
                              : m.email),
                        );
                      }),
                    ],
                    onChanged: (v) => setState(() => selectedMemberId = v),
                  ),
                  const SizedBox(height: 16),
                  Text(l.fromDateLabel,
                      style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: fromDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => fromDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(dateFormat.format(fromDate)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('${l.toDateLabel} (${l.optional})',
                      style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: toDate ?? fromDate,
                        firstDate: fromDate,
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => toDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixIcon: toDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setState(() => toDate = null),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(toDate != null
                          ? dateFormat.format(toDate!)
                          : l.notSet),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: l.notes,
                      prefixIcon: const Icon(Icons.notes),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await ref
                        .read(familyEventsProvider(petId).notifier)
                        .createEvent(
                          assignedToUserId: selectedMemberId,
                          fromDate: fromDate,
                          toDate: toDate,
                          notes: notesController.text.trim(),
                        );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    }
                  }
                },
                child: Text(l.save),
              ),
            ],
          );
        },
      ),
    );
  }
}
