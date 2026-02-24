import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../health_tracking/domain/entities/health_entry.dart';

class SharedPetScreen extends ConsumerStatefulWidget {
  const SharedPetScreen({super.key, required this.shareCode});

  final String shareCode;

  @override
  ConsumerState<SharedPetScreen> createState() => _SharedPetScreenState();
}

class _SharedPetScreenState extends ConsumerState<SharedPetScreen> {
  Map<String, dynamic>? _petData;
  List<Map<String, dynamic>> _healthEntries = [];
  Map<String, dynamic>? _vetData;
  bool _loading = true;
  String? _error;

  String get _baseUrl => kIsWeb ? '' : 'http://localhost:5000';

  @override
  void initState() {
    super.initState();
    _loadSharedPet();
  }

  Future<void> _loadSharedPet() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/share/${widget.shareCode}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _petData = data['pet'] as Map<String, dynamic>?;
          _healthEntries = (data['health_entries'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
          _vetData = data['vet'] as Map<String, dynamic>?;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Pet not found or share link expired';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load shared pet';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _petData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shared Pet')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link_off, size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(_error ?? 'Something went wrong',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Go to My Pets'),
              ),
            ],
          ),
        ),
      );
    }

    final pet = _petData!;
    final name = pet['name'] as String? ?? 'Unknown';
    final species = pet['species'] as String? ?? '';
    final breed = pet['breed'] as String? ?? '';
    final age = (pet['age'] as num?)?.toDouble();
    final weight = (pet['weight'] as num?)?.toDouble();
    final bio = pet['bio'] as String? ?? '';
    final photoPath = pet['photoPath'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              avatar: Icon(Icons.visibility, size: 16,
                  color: colorScheme.onSecondaryContainer),
              label: Text('View Only',
                  style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSecondaryContainer)),
              backgroundColor: colorScheme.secondaryContainer,
              side: BorderSide.none,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 140,
                    child: _buildPhoto(photoPath, colorScheme),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildChip(Icons.category, species, colorScheme),
                              if (breed.isNotEmpty)
                                _buildChip(Icons.pets, breed, colorScheme),
                              if (age != null)
                                _buildChip(Icons.cake,
                                    '${age.toStringAsFixed(1)} yrs', colorScheme),
                              if (weight != null)
                                _buildChip(Icons.monitor_weight,
                                    '${weight.toStringAsFixed(1)} kg', colorScheme),
                            ],
                          ),
                          if (_vetData != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.local_hospital, size: 16,
                                    color: colorScheme.primary),
                                const SizedBox(width: 6),
                                Text(_vetData!['name'] ?? '',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                          if (bio.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(bio,
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

          if (_vetData != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.local_hospital, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Veterinarian', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            _buildVetCard(theme, colorScheme),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.medical_services, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text('Health Tracking', style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 8),
          if (_healthEntries.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.medical_services_outlined,
                          size: 48, color: colorScheme.outline),
                      const SizedBox(height: 12),
                      Text('No health entries yet',
                          style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._healthEntries.map((e) => _buildHealthEntryCard(e, theme, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildPhoto(String? photoPath, ColorScheme colorScheme) {
    if (photoPath != null && photoPath.isNotEmpty) {
      try {
        final bytes = base64Decode(photoPath);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {}
    }
    return Container(
      color: colorScheme.primaryContainer,
      child: Center(
        child: Icon(Icons.pets, size: 56,
            color: colorScheme.onPrimaryContainer.withAlpha(100)),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, ColorScheme colorScheme) {
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

  Widget _buildVetCard(ThemeData theme, ColorScheme colorScheme) {
    final vet = _vetData!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vet['name'] ?? '', style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
            if ((vet['phone'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.phone, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(vet['phone'], style: theme.textTheme.bodyMedium),
              ]),
            ],
            if ((vet['email'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.email, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(vet['email'], style: theme.textTheme.bodyMedium),
              ]),
            ],
            if ((vet['address'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(child: Text(vet['address'],
                      style: theme.textTheme.bodyMedium)),
                ],
              ),
            ],
            if ((vet['notes'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(vet['notes'], style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHealthEntryCard(
      Map<String, dynamic> entry, ThemeData theme, ColorScheme colorScheme) {
    final name = entry['name']?.toString() ?? '';
    final type = entry['type']?.toString() ?? '';
    final dosage = entry['dosage']?.toString() ?? '';
    final frequency = entry['frequency']?.toString() ?? '';
    final nextDue = entry['next_due_date']?.toString() ?? '';
    final notes = entry['notes']?.toString() ?? '';

    DateTime? dueDate;
    try {
      dueDate = DateTime.parse(nextDue);
    } catch (_) {}

    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());
    final isDueToday = dueDate != null &&
        dueDate.year == DateTime.now().year &&
        dueDate.month == DateTime.now().month &&
        dueDate.day == DateTime.now().day;

    Color statusColor;
    String statusLabel;
    if (isOverdue && !isDueToday) {
      statusColor = colorScheme.error;
      statusLabel = 'Overdue';
    } else if (isDueToday) {
      statusColor = Colors.orange;
      statusLabel = 'Due Today';
    } else {
      statusColor = colorScheme.primary;
      statusLabel = 'Upcoming';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name, style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(fontSize: 11, color: statusColor,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _entryDetail(Icons.category, _capitalize(type), colorScheme),
                if (dosage.isNotEmpty)
                  _entryDetail(Icons.medication, dosage, colorScheme),
                _entryDetail(Icons.schedule, _capitalize(frequency), colorScheme),
                if (dueDate != null)
                  _entryDetail(Icons.event,
                      '${dueDate.day}/${dueDate.month}/${dueDate.year}', colorScheme),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(notes, style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _entryDetail(IconData icon, String text, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12,
            color: colorScheme.onSurfaceVariant)),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
