import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../health_tracking/presentation/widgets/health_entry_card.dart';
import '../../../vet/presentation/providers/vet_providers.dart';
import '../../../weight_tracking/domain/entities/weight_entry.dart';
import '../../../weight_tracking/presentation/providers/weight_providers.dart';
import '../../data/models/pet_model.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_providers.dart';

class PetDetailScreen extends ConsumerStatefulWidget {
  const PetDetailScreen({super.key, required this.petId});

  final String petId;

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {

  Future<void> _sharePet(BuildContext context, Pet pet) async {
    final baseUrl = kIsWeb ? '' : 'http://localhost:5000';
    final petJson = PetModel.fromEntity(pet).toJson();
    petJson.remove('photoPath');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/share'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'pet': petJson, 'pet_id': pet.id}),
      );

      if (!context.mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final code = data['share_code'] as String;
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create share link')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e')),
      );
    }
  }

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

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(pet.name),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/'),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: 'Share Pet',
                    onPressed: () => _sharePet(context, pet),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Pet',
                    onPressed: () => context.go('/edit/${pet.id}'),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: _PetProfileCard(pet: pet),
              ),
              SliverToBoxAdapter(
                child: _WeightTrackingSection(petId: widget.petId),
              ),
              SliverToBoxAdapter(
                child: _HealthEventsSection(petId: widget.petId),
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
                      Text(pet.name, style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(icon: Icons.category, label: pet.species),
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
      return GestureDetector(
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
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        _showAddWeightSheet(context, ref, unit, unitLabel),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Entry'),
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
                InkWell(
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

    return ListTile(
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
        onPressed: onDelete,
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

    return LineChart(
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
    );
  }
}

class _PetPhoto extends StatelessWidget {
  const _PetPhoto({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (pet.photoPath != null && pet.photoPath!.isNotEmpty) {
      try {
        final bytes = base64Decode(pet.photoPath!);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
        );
      } catch (_) {}
    }

    return Container(
      color: colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.pets,
          size: 56,
          color: colorScheme.onPrimaryContainer.withAlpha(100),
        ),
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

class _HealthEventsSection extends ConsumerStatefulWidget {
  const _HealthEventsSection({required this.petId});

  final String petId;

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
          title: Text('Health Events',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        context.go('/pet/${widget.petId}/health/add'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Entry'),
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
                      label: 'Vaccines',
                      selected: _selectedFilter == HealthEntryType.vaccine,
                      onSelected: () => setState(
                          () => _selectedFilter = HealthEntryType.vaccine),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipWidget(
                      label: 'Procedures',
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
                                      Text('${entry.name} marked as taken')),
                            );
                          }
                        },
                        onDelete: () async {
                          await ref
                              .read(healthEntriesNotifierProvider.notifier)
                              .delete(entry.id);
                          ref.invalidate(
                              petHealthEntriesProvider(widget.petId));
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
