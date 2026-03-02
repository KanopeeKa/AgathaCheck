import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/constants.dart';
import '../../data/services/pdf_saver.dart' as pdf_saver;
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/domain/entities/health_issue.dart';
import '../../../health_tracking/presentation/providers/health_issue_providers.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../health_tracking/presentation/widgets/health_entry_card.dart';
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

    return petListAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Pet Details')),
        body: Center(child: Text('Error: $error')),
      ),
      data: (pets) {
        final pet = pets.where((p) => p.id == widget.petId).firstOrNull;
        if (pet == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Pet Details')),
            body: const Center(child: Text('Pet not found')),
          );
        }

        final auth = ref.watch(authProvider);
        final theme = Theme.of(context);
        final unreadCount = ref.watch(unreadNotificationCountProvider);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(pet.name),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Go back',
                  onPressed: () => context.go('/'),
                ),
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        tooltip: 'Notifications',
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
                    tooltip: 'Veterinarians',
                    onPressed: () => context.go('/vets'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.list_alt),
                    tooltip: 'Events',
                    onPressed: () => context.go('/health'),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'User menu',
                    icon: CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        ((auth.user?.name.isNotEmpty ?? false)
                                ? auth.user!.name[0]
                                : auth.user?.email[0] ?? 'U')
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
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.user?.name.isNotEmpty == true
                                  ? auth.user!.name
                                  : 'User',
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
                      const PopupMenuItem<String>(
                        value: 'details',
                        child: ListTile(
                          leading: Icon(Icons.person_outlined),
                          title: Text('My Details'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: ListTile(
                          leading: Icon(Icons.logout),
                          title: Text('Log Out'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
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
                child: _WeightTrackingSection(petId: widget.petId),
              ),
              SliverToBoxAdapter(
                child: _HealthEventsSection(petId: widget.petId, pet: pet),
              ),
              SliverToBoxAdapter(
                child: _HealthIssuesSection(petId: widget.petId, pet: pet),
              ),
              SliverToBoxAdapter(
                child: _SharingSection(petId: widget.petId, pet: pet),
              ),
              SliverToBoxAdapter(
                child: _DownloadReportSection(pet: pet),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        );
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
                            tooltip: 'Edit Pet',
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
                          if (pet.age != null)
                            _InfoChip(
                                icon: Icons.cake,
                                label: '${pet.age!.toStringAsFixed(1)} yrs'),
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
                            Text('Neutered / Spayed: ${DateFormat.yMMMd().format(pet.neuteredDate!)}',
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
                            Text('ID: ${pet.chipId}',
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
                                  Text('Insurance Details',
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
    if (vets.isEmpty) {
      return Semantics(
        label: 'Add a veterinarian. No vets yet.',
        button: true,
        child: GestureDetector(
        onTap: () => GoRouter.of(context).go('/vets/add'),
        child: Row(
          children: [
            Icon(Icons.local_hospital, size: 16,
                color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text('No vet assigned',
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
            tooltip: 'Select veterinarian',
            padding: EdgeInsets.zero,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  assignedVet != null ? assignedVet.name : 'No vet assigned',
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
                const PopupMenuItem<String?>(
                  value: null,
                  child: Text('Remove vet'),
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
    final unitLabel = weightUnitLabel(unit);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: Icon(Icons.monitor_weight, color: colorScheme.primary),
          title: Text('Weight Tracking',
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
                    message: 'Add weight entry',
                    child: FilledButton.tonalIcon(
                      onPressed: () =>
                          _showAddWeightSheet(context, ref, unit, unitLabel),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Entry'),
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
                child: Text('Error loading weight data: $error',
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
                        Text('No weight data yet',
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('Tap "Add Entry" to start tracking',
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
                Text('Add Weight Entry',
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
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
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
                    labelText: 'Weight ($unitLabel)',
                    prefixIcon: const Icon(Icons.monitor_weight),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
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
                  child: const Text('Save'),
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
          tooltip: 'Delete weight entry',
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
      label: 'Weight chart showing ${entries.length} entries',
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
      return Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0xBBFFFFFF),
              BlendMode.lighten,
            ),
            child: photoContent,
          ),
          Center(
            child: Opacity(
              opacity: 0.45,
              child: Image.asset(
                'assets/rainbow_wings.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      );
    }

    return photoContent;
  }

  Widget _buildPlaceholder(Color petColor) {
    return Container(
      decoration: BoxDecoration(
        color: petColor.withOpacity(0.12),
        border: Border(left: BorderSide(color: petColor, width: 5)),
      ),
      child: Center(
        child: AppConstants.speciesIconWidget(pet.species, size: 56, color: petColor.withOpacity(0.6)),
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

class _HealthEventsSection extends ConsumerStatefulWidget {
  const _HealthEventsSection({required this.petId, this.pet});

  final String petId;
  final Pet? pet;

  @override
  ConsumerState<_HealthEventsSection> createState() =>
      _HealthEventsSectionState();
}

class _HealthEventsSectionState extends ConsumerState<_HealthEventsSection> {
  HealthEntryType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entriesAsync = ref.watch(petHealthEntriesProvider(widget.petId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: Icon(Icons.list_alt, color: colorScheme.primary),
          title: Text('Events',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: 'Add health entry',
                    child: FilledButton.tonalIcon(
                      onPressed: () =>
                          context.go('/pet/${widget.petId}/health/add'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Entry'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChipWidget(
                      label: 'All',
                      selected: _selectedFilter == null,
                      onSelected: () =>
                          setState(() => _selectedFilter = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipWidget(
                      label: 'Medications',
                      selected:
                          _selectedFilter == HealthEntryType.medication,
                      onSelected: () => setState(
                          () => _selectedFilter = HealthEntryType.medication),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipWidget(
                      label: 'Preventives',
                      selected:
                          _selectedFilter == HealthEntryType.preventive,
                      onSelected: () => setState(
                          () => _selectedFilter = HealthEntryType.preventive),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipWidget(
                      label: 'Vet Visits',
                      selected: _selectedFilter == HealthEntryType.vetVisit,
                      onSelected: () => setState(
                          () => _selectedFilter = HealthEntryType.vetVisit),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipWidget(
                      label: 'Other',
                      selected:
                          _selectedFilter == HealthEntryType.procedure,
                      onSelected: () => setState(
                          () => _selectedFilter = HealthEntryType.procedure),
                    ),
                  ],
                ),
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
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48,
                        color: colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Error: $error', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref
                          .invalidate(petHealthEntriesProvider(widget.petId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (allEntries) {
                final entries = _selectedFilter == null
                    ? allEntries
                    : allEntries
                        .where((e) => e.type == _selectedFilter)
                        .toList();

                if (entries.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.list_alt, size: 48,
                            color: colorScheme.outline),
                        const SizedBox(height: 8),
                        Text(
                          _selectedFilter == null
                              ? 'No health events yet'
                              : 'No ${_selectedFilter!.label.toLowerCase()}s yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text('Tap "Add Entry" to start tracking',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.outline)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: HealthEntryCard(
                        entry: entry,
                        pet: widget.pet,
                        healthIssueName: entry.healthIssueName,
                        onTap: () => context.go(
                            '/pet/${widget.petId}/health/edit/${entry.id}'),
                        onMarkTaken: () async {
                          await ref
                              .read(healthEntriesNotifierProvider.notifier)
                              .markTaken(entry.id);
                          ref.invalidate(
                              petHealthEntriesProvider(widget.petId));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('${entry.name} marked as done')),
                            );
                          }
                        },
                        onSnooze: (days) async {
                          await ref
                              .read(healthEntriesNotifierProvider.notifier)
                              .snooze(entry.id, days);
                          ref.invalidate(
                              petHealthEntriesProvider(widget.petId));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '${entry.name} snoozed for $days ${days == 1 ? 'day' : 'days'}')),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FilterChipWidget extends StatelessWidget {
  const _FilterChipWidget({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _SharingSection extends ConsumerWidget {
  const _SharingSection({required this.petId, required this.pet});

  final String petId;
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final baseUrl = kIsWeb ? '' : 'http://localhost:5000';

    if (!authState.isLoggedIn) {
      return const SizedBox.shrink();
    }

    final currentUserId = int.tryParse(authState.user?.id ?? '') ?? 0;
    final accessAsync = ref.watch(petAccessNotifierProvider(petId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: Icon(Icons.people, color: colorScheme.primary),
          title: Text('Sharing',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          children: [
            accessAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48,
                        color: colorScheme.error),
                    const SizedBox(height: 8),
                    Text('Could not load sharing info',
                        style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => ref
                          .read(petAccessNotifierProvider(petId).notifier)
                          .refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (accessList) {
                final isGuardian = accessList.any(
                    (a) => a.userId == currentUserId && a.role == PetAccessRole.guardian);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilledButton.tonalIcon(
                              onPressed: () async {
                                final petJson = PetModel.fromEntity(pet).toJson();
                                petJson.remove('photoPath');
                                try {
                                  final ds = ref.read(sharingDataSourceProvider);
                                  final code = await ds.createShare(
                                      petId, petJson, authState.accessToken!);
                                  if (!context.mounted) return;
                                  final uri = Uri.base;
                                  final shareUrl = '${uri.scheme}://${uri.host}'
                                      '${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}'
                                      '/shared/$code';
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Share Link'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Share this link so others can view ${pet.name}\'s profile:'),
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: SelectableText(shareUrl,
                                                style: const TextStyle(fontSize: 13)),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Close'),
                                        ),
                                        FilledButton.icon(
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: shareUrl));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Link copied to clipboard')),
                                            );
                                            Navigator.pop(ctx);
                                          },
                                          icon: const Icon(Icons.copy),
                                          label: const Text('Copy'),
                                        ),
                                      ],
                                    ),
                                  );
                                  ref.read(petAccessNotifierProvider(petId).notifier).refresh();
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text('Share Pet'),
                            ),
                          ],
                        ),
                      ),
                    if (accessList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 48,
                                color: colorScheme.outline),
                            const SizedBox(height: 8),
                            Text('No one else has access yet',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: accessList.length,
                        itemBuilder: (context, index) {
                          final access = accessList[index];
                          final user = access.user;
                          final displayName = user?.displayName ?? 'User #${access.userId}';
                          final initials = user?.initials ?? '?';
                          final photoUrl = user?.photoUrl ?? '';
                          final category = user?.category ?? 'pet_guardian';
                          final isProfessional = category == 'professional_multi_pet';
                          final isCurrentUser = access.userId == currentUserId;

                          Widget avatar;
                          if (photoUrl.isNotEmpty) {
                            final imageUrl = photoUrl.startsWith('http')
                                ? photoUrl
                                : '$baseUrl/$photoUrl';
                            avatar = CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(imageUrl),
                            );
                          } else {
                            avatar = CircleAvatar(
                              radius: 20,
                              backgroundColor: colorScheme.primaryContainer,
                              child: Text(initials,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimaryContainer)),
                            );
                          }

                          final roleBadgeColor = access.role == PetAccessRole.guardian
                              ? Colors.deepPurple
                              : Colors.grey;
                          final roleBadgeLabel = access.role == PetAccessRole.guardian
                              ? 'Guardian'
                              : 'Shared';

                          return MergeSemantics(
                            child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: avatar,
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    displayName + (isCurrentUser ? ' (you)' : ''),
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Semantics(
                                  label: 'Role: $roleBadgeLabel',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: roleBadgeColor.withAlpha(30),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(roleBadgeLabel,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: roleBadgeColor,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: isProfessional
                                ? Text('Professional Multi Pet',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.teal))
                                : null,
                            trailing: isGuardian && !isCurrentUser
                                ? PopupMenuButton<String>(
                                    tooltip: 'Manage user access',
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(
                                        value: 'toggle_role',
                                        child: Text(access.role == PetAccessRole.guardian
                                            ? 'Demote to Shared'
                                            : 'Promote to Guardian'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'remove',
                                        child: Text('Remove Access'),
                                      ),
                                    ],
                                    onSelected: (action) async {
                                      final notifier = ref.read(
                                          petAccessNotifierProvider(petId).notifier);
                                      try {
                                        if (action == 'toggle_role') {
                                          final newRole = access.role == PetAccessRole.guardian
                                              ? PetAccessRole.shared
                                              : PetAccessRole.guardian;
                                          await notifier.updateRole(access.userId, newRole);
                                        } else if (action == 'remove') {
                                          await notifier.removeAccess(access.userId);
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e')),
                                          );
                                        }
                                      }
                                    },
                                  )
                                : null,
                          ),
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
}

class _NeuterReminderCard extends ConsumerWidget {
  const _NeuterReminderCard({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: colorScheme.tertiaryContainer.withAlpha(80),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.tertiary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pet.species == 'Other'
                          ? 'Has ${pet.name} been neutered or spayed?'
                          : 'Consider neutering ${pet.name}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                pet.species == 'Other'
                    ? 'Neutering or spaying is not suitable for every species. '
                      'If your pet is a species where neutering applies, it can '
                      'help prevent certain health issues and control the population. '
                      'Talk to your vet to find out if it is appropriate for your pet.'
                    : 'Neutering or spaying helps prevent certain cancers, '
                      'reduces unwanted behaviours, and helps control the pet '
                      'population. It can also lower the risk of infections and '
                      'increase your pet\'s lifespan. Talk to your vet about the '
                      'best time for the procedure.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onTertiaryContainer.withAlpha(200),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('neuter_dismiss_button'),
                    onPressed: () async {
                      final updated = pet.copyWith(neuterDismissed: true);
                      await ref.read(petListProvider.notifier).updatePet(updated);
                    },
                    child: const Text('I don\'t want to neuter'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    key: const Key('neuter_snooze_button'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reminder snoozed. We\'ll remind you again later.'),
                        ),
                      );
                    },
                    child: const Text('Snooze'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipReminderCard extends ConsumerWidget {
  const _ChipReminderCard({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: colorScheme.secondaryContainer.withAlpha(80),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.memory, color: colorScheme.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppConstants.identificationTitle(pet.species, pet.name),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                AppConstants.identificationMessage(pet.species),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSecondaryContainer.withAlpha(200),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('chip_dismiss_button'),
                    onPressed: () async {
                      final updated = pet.copyWith(chipDismissed: true);
                      await ref.read(petListProvider.notifier).updatePet(updated);
                    },
                    child: const Text('I don\'t want to chip / identify my pet'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    key: const Key('chip_snooze_button'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reminder snoozed. We\'ll remind you again later.'),
                        ),
                      );
                    },
                    child: const Text('Snooze'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadReportSection extends ConsumerWidget {
  const _DownloadReportSection({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FilledButton.icon(
        key: const Key('download_report_button'),
        onPressed: () => _showReportSheet(context, ref),
        icon: const Icon(Icons.description),
        label: const Text('Download Pet Report'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReportSelectionSheet(pet: pet),
    );
  }
}

class _ReportSelectionSheet extends ConsumerStatefulWidget {
  const _ReportSelectionSheet({required this.pet});

  final Pet pet;

  @override
  ConsumerState<_ReportSelectionSheet> createState() =>
      _ReportSelectionSheetState();
}

class _ReportSelectionSheetState extends ConsumerState<_ReportSelectionSheet> {
  final bool _includeProfile = true;
  bool _includeWeight = true;
  bool _includeHealth = true;
  bool _includeHealthIssues = true;
  bool _includeSharing = false;
  bool _includeFullLog = false;
  bool _isGenerating = false;

  late DateTime _healthFrom;
  late DateTime _healthTo;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _healthTo = now;
    _healthFrom = DateTime(now.year, now.month - 6, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Pet Report',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Choose which sections to include',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          CheckboxListTile(
            value: _includeProfile,
            onChanged: null,
            title: const Text('Pet Profile'),
            subtitle: const Text('Basic info, vet details'),
            secondary: Icon(Icons.pets, color: colorScheme.primary),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            value: _includeWeight,
            onChanged: (v) => setState(() => _includeWeight = v ?? false),
            title: const Text('Weight Tracking'),
            subtitle: const Text('Chart and data table'),
            secondary: Icon(Icons.monitor_weight, color: colorScheme.primary),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            value: _includeHealth,
            onChanged: (v) => setState(() => _includeHealth = v ?? false),
            title: const Text('Events'),
            subtitle: const Text('Medications, preventives, vet visits'),
            secondary: Icon(Icons.list_alt, color: colorScheme.primary),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          if (_includeHealth)
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: CheckboxListTile(
                value: _includeFullLog,
                onChanged: (v) =>
                    setState(() => _includeFullLog = v ?? false),
                title: const Text('Include full log for each event'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          CheckboxListTile(
            value: _includeHealthIssues,
            onChanged: (v) =>
                setState(() => _includeHealthIssues = v ?? false),
            title: const Text('Health Issues'),
            subtitle: const Text('Ongoing conditions and linked events'),
            secondary:
                Icon(Icons.health_and_safety, color: colorScheme.primary),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            value: _includeSharing,
            onChanged: (v) => setState(() => _includeSharing = v ?? false),
            title: const Text('Sharing'),
            subtitle: const Text('People with access to this pet'),
            secondary: Icon(Icons.people, color: colorScheme.primary),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: Icon(Icons.calendar_month, color: colorScheme.primary),
            title: const Text('Print events range'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: 'From',
                    date: _healthFrom,
                    onChanged: (d) =>
                        setState(() => _healthFrom = d),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerField(
                    label: 'To',
                    date: _healthTo,
                    onChanged: (d) =>
                        setState(() => _healthTo = d),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isGenerating ? null : _generateReport,
            icon: _isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(_isGenerating ? 'Generating...' : 'Generate PDF'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);

    try {
      final pet = widget.pet;

      final weightEntries =
          await ref.read(weightEntriesNotifierProvider(pet.id).future);

      List<HealthEntry> healthEntries = [];
      Map<String, List<Map<String, dynamic>>> histories = {};

      if (_includeHealth || _includeHealthIssues) {
        healthEntries =
            await ref.read(petHealthEntriesProvider(pet.id).future);

        if (_includeHealth && _includeFullLog) {
          final repo = ref.read(healthRepositoryProvider);
          for (final entry in healthEntries) {
            try {
              final h = await repo.getHistory(entry.id);
              histories[entry.id] = h
                  .map((he) => {
                        'taken_at': he.takenAt.toIso8601String(),
                        'notes': he.notes,
                      })
                  .toList();
            } catch (_) {}
          }
        }
      }

      List<HealthIssue> healthIssues = [];
      if (_includeHealthIssues) {
        try {
          healthIssues =
              await ref.read(petHealthIssuesProvider(pet.id).future);
        } catch (_) {}
      }

      List<PetAccess> accessList = [];
      if (_includeSharing) {
        try {
          accessList = await ref.read(petAccessProvider(pet.id).future);
        } catch (_) {}
      }

      final vetsAsync = ref.read(vetListProvider);
      final vets = vetsAsync.valueOrNull ?? [];
      final assignedVet = (pet.vetId != null && pet.vetId!.isNotEmpty)
          ? vets.where((v) => v.id == pet.vetId).firstOrNull
          : null;

      final unit = ref.read(weightUnitProvider(pet.id));
      final unitLabel = unit == WeightUnit.lb ? 'lb' : 'kg';

      Uint8List? logoBytes;
      try {
        final logoData = await rootBundle.load('assets/logo.png');
        logoBytes = logoData.buffer.asUint8List();
      } catch (_) {}

      final service = PetReportService();
      final pdfBytes = await service.generateReport(
        pet: pet,
        sections: ReportSections(
          petProfile: _includeProfile,
          weightTracking: _includeWeight,
          healthEvents: _includeHealth,
          healthIssues: _includeHealthIssues,
          sharing: _includeSharing,
          healthFrom: _healthFrom,
          healthTo: _healthTo,
          includeFullLog: _includeFullLog,
        ),
        vet: assignedVet,
        weightEntries: weightEntries,
        healthEntries: healthEntries,
        healthIssues: healthIssues,
        accessList: accessList,
        healthHistories: histories,
        weightUnit: unitLabel,
        logoBytes: logoBytes,
      );

      if (!mounted) return;
      Navigator.pop(context);

      final filename = '${pet.name.replaceAll(' ', '_')}_report.pdf';
      await pdf_saver.savePdf(pdfBytes, filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Semantics(
      label: '$label: ${dateFormat.format(date)}. Tap to change.',
      button: true,
      child: InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        child: Text(dateFormat.format(date),
            style: const TextStyle(fontSize: 13)),
      ),
    ),
    );
  }
}

class _HealthIssuesSection extends ConsumerStatefulWidget {
  const _HealthIssuesSection({required this.petId, this.pet});

  final String petId;
  final Pet? pet;

  @override
  ConsumerState<_HealthIssuesSection> createState() =>
      _HealthIssuesSectionState();
}

class _HealthIssuesSectionState extends ConsumerState<_HealthIssuesSection> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final issuesAsync = ref.watch(healthIssueNotifierProvider(widget.petId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: Icon(Icons.health_and_safety, color: colorScheme.primary),
          title: Text('Health Issues',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: 'Add health issue',
                    child: FilledButton.tonalIcon(
                      key: const Key('add_health_issue_button'),
                      onPressed: () => _showCreateIssueSheet(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Issue'),
                    ),
                  ),
                ],
              ),
            ),
            issuesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $error',
                    style: TextStyle(color: colorScheme.error)),
              ),
              data: (issues) {
                if (issues.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.health_and_safety_outlined,
                            size: 40, color: colorScheme.outline),
                        const SizedBox(height: 8),
                        Text('No health issues yet',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.outline)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: issues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final issue = issues[index];
                    return _HealthIssueCard(
                      key: Key('health_issue_card_${issue.id}'),
                      issue: issue,
                      petId: widget.petId,
                      onEdit: () => _showEditIssueSheet(context, issue),
                      onDelete: () => _confirmDeleteIssue(context, issue),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showCreateIssueSheet(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? startDate;
    DateTime? endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('New Health Issue',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('health_issue_title_field'),
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Skin allergy, Hip dysplasia',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('health_issue_description_field'),
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Details about the condition',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _OptionalDateField(
                        label: 'Start Date',
                        date: startDate,
                        onChanged: (d) => setSheetState(() => startDate = d),
                        onClear: () => setSheetState(() => startDate = null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OptionalDateField(
                        label: 'End Date',
                        date: endDate,
                        onChanged: (d) => setSheetState(() => endDate = d),
                        onClear: () => setSheetState(() => endDate = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('save_health_issue_button'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final issue = HealthIssue(
                      id: '',
                      petId: widget.petId,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      startDate: startDate,
                      endDate: endDate,
                    );
                    await ref
                        .read(healthIssueNotifierProvider(widget.petId).notifier)
                        .create(issue);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditIssueSheet(BuildContext context, HealthIssue issue) {
    final titleController = TextEditingController(text: issue.title);
    final descriptionController =
        TextEditingController(text: issue.description);
    final formKey = GlobalKey<FormState>();
    DateTime? startDate = issue.startDate;
    DateTime? endDate = issue.endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Edit Health Issue',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _OptionalDateField(
                        label: 'Start Date',
                        date: startDate,
                        onChanged: (d) => setSheetState(() => startDate = d),
                        onClear: () => setSheetState(() => startDate = null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OptionalDateField(
                        label: 'End Date',
                        date: endDate,
                        onChanged: (d) => setSheetState(() => endDate = d),
                        onClear: () => setSheetState(() => endDate = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final updated = issue.copyWith(
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      startDate: startDate,
                      endDate: endDate,
                      clearStartDate: startDate == null,
                      clearEndDate: endDate == null,
                    );
                    await ref
                        .read(healthIssueNotifierProvider(widget.petId).notifier)
                        .updateIssue(updated);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteIssue(
      BuildContext context, HealthIssue issue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Health Issue'),
        content: Text(
            'Are you sure you want to delete "${issue.title}"? Linked events will be unlinked but not deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(healthIssueNotifierProvider(widget.petId).notifier)
          .deleteIssue(issue.id);
    }
  }
}

class _HealthIssueCard extends ConsumerStatefulWidget {
  const _HealthIssueCard({
    super.key,
    required this.issue,
    required this.petId,
    required this.onEdit,
    required this.onDelete,
  });

  final HealthIssue issue;
  final String petId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  ConsumerState<_HealthIssueCard> createState() => _HealthIssueCardState();
}

class _HealthIssueCardState extends ConsumerState<_HealthIssueCard> {
  bool _expanded = false;

  String _formatDateRange(DateTime? start, DateTime? end) {
    final fmt = DateFormat('MMM d, yyyy');
    if (start != null && end != null) return '${fmt.format(start)} – ${fmt.format(end)}';
    if (start != null) return 'From ${fmt.format(start)}';
    return 'Until ${fmt.format(end!)}';
  }

  Future<void> _unlinkEvent(HealthIssue issue, HealthEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink Event'),
        content: Text('Remove "${entry.name}" from "${issue.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(healthIssueNotifierProvider(widget.petId).notifier)
        .unlinkEvent(issue.id, entry.id);
    ref.invalidate(petHealthEntriesProvider(widget.petId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final issue = widget.issue;
    final eventCount = issue.eventIds.length;

    return MergeSemantics(
      child: Semantics(
        label: 'Health issue: ${issue.title}, $eventCount linked events',
        child: Card(
          elevation: 0.5,
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Icon(Icons.health_and_safety,
                            color: colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(issue.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold)),
                            if (issue.description.isNotEmpty)
                              Text(issue.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            if (issue.startDate != null || issue.endDate != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    ExcludeSemantics(
                                      child: Icon(Icons.calendar_today,
                                          size: 12, color: colorScheme.outline),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDateRange(issue.startDate, issue.endDate),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.outline, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$eventCount event${eventCount != 1 ? 's' : ''}',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                              fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Edit health issue',
                        onPressed: widget.onEdit,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 18, color: colorScheme.error),
                        tooltip: 'Delete health issue',
                        onPressed: widget.onDelete,
                        visualDensity: VisualDensity.compact,
                      ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) _buildLinkedEvents(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkedEvents(ThemeData theme, ColorScheme colorScheme) {
    final issue = widget.issue;
    if (issue.eventIds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text('No events linked yet',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colorScheme.outline)),
      );
    }

    final healthEntriesAsync =
        ref.watch(petHealthEntriesProvider(widget.petId));
    return healthEntriesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (entries) {
        final linked =
            entries.where((e) => issue.eventIds.contains(e.id)).toList();
        if (linked.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text('Linked events not found',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.outline)),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Column(
            children: linked.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        _entryIcon(entry.type),
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entry.name,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text(
                      entry.type.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant, fontSize: 10),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Unlink event',
                      child: InkWell(
                        onTap: () => _unlinkEvent(issue, entry),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.link_off, size: 16,
                              color: colorScheme.error),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  IconData _entryIcon(HealthEntryType type) {
    switch (type) {
      case HealthEntryType.medication:
        return Icons.medication;
      case HealthEntryType.preventive:
        return Icons.shield;
      case HealthEntryType.vetVisit:
        return Icons.local_hospital;
      case HealthEntryType.procedure:
        return Icons.more_horiz;
    }
  }
}

class _OptionalDateField extends StatelessWidget {
  const _OptionalDateField({
    required this.label,
    required this.date,
    required this.onChanged,
    required this.onClear,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Semantics(
      label: date != null
          ? '$label: ${dateFormat.format(date!)}. Tap to change.'
          : '$label: not set. Tap to pick a date.',
      button: true,
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now().add(const Duration(days: 3650)),
          );
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            suffixIcon: date != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    tooltip: 'Clear $label',
                    onPressed: onClear,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : null,
          ),
          child: Text(
            date != null ? dateFormat.format(date!) : 'Not set',
            style: TextStyle(
              fontSize: 13,
              color: date != null ? null : Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }
}
