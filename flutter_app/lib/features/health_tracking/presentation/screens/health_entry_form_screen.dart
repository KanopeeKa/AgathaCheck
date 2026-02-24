import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/health_entry.dart';
import '../providers/health_providers.dart';

/// Form screen for creating or editing a health entry.
///
/// When [entryId] is provided, loads the existing entry for editing.
/// Otherwise, creates a new entry.
class HealthEntryFormScreen extends ConsumerStatefulWidget {
  /// Creates the [HealthEntryFormScreen].
  const HealthEntryFormScreen({super.key, this.entryId});

  /// The ID of the entry to edit, or null for a new entry.
  final String? entryId;

  @override
  ConsumerState<HealthEntryFormScreen> createState() =>
      _HealthEntryFormScreenState();
}

class _HealthEntryFormScreenState
    extends ConsumerState<HealthEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  final _customDaysController = TextEditingController();

  HealthEntryType _type = HealthEntryType.medication;
  HealthFrequency _frequency = HealthFrequency.daily;
  DateTime _startDate = DateTime.now();
  DateTime _nextDueDate = DateTime.now();
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.entryId != null) {
      _isEdit = true;
      _loadEntry();
    }
  }

  Future<void> _loadEntry() async {
    setState(() => _isLoading = true);
    try {
      final entry = await ref
          .read(healthRepositoryProvider)
          .getEntry(widget.entryId!);
      if (entry != null && mounted) {
        setState(() {
          _nameController.text = entry.name;
          _dosageController.text = entry.dosage;
          _notesController.text = entry.notes;
          _type = entry.type;
          _frequency = entry.frequency;
          _startDate = entry.startDate;
          _nextDueDate = entry.nextDueDate;
          if (entry.frequencyDays != null) {
            _customDaysController.text = entry.frequencyDays.toString();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load entry: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Entry' : 'New Health Entry'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/health'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<HealthEntryType>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: HealthEntryType.values.map((t) {
                        return DropdownMenuItem(
                            value: t, child: Text(t.label));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _type = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g., Heartgard, Rabies Vaccine',
                        prefixIcon: Icon(Icons.medical_services),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty
                              ? 'Name is required'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage / Amount',
                        hintText: 'e.g., 1 tablet, 0.5ml',
                        prefixIcon: Icon(Icons.straighten),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<HealthFrequency>(
                      value: _frequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        prefixIcon: Icon(Icons.repeat),
                      ),
                      items: HealthFrequency.values.map((f) {
                        return DropdownMenuItem(
                            value: f, child: Text(f.label));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _frequency = val);
                      },
                    ),
                    if (_frequency == HealthFrequency.custom) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customDaysController,
                        decoration: const InputDecoration(
                          labelText: 'Interval (days)',
                          hintText: 'e.g., 14',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (_frequency == HealthFrequency.custom) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Enter number of days';
                            }
                            final n = int.tryParse(val.trim());
                            if (n == null || n < 1) {
                              return 'Enter a valid number of days';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    _DatePickerField(
                      label: 'Start Date',
                      date: _startDate,
                      onChanged: (d) => setState(() => _startDate = d),
                    ),
                    const SizedBox(height: 16),
                    _DatePickerField(
                      label: 'Next Due Date',
                      date: _nextDueDate,
                      onChanged: (d) => setState(() => _nextDueDate = d),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Additional information...',
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: Icon(_isEdit ? Icons.save : Icons.add),
                      label: Text(_isEdit ? 'Save Changes' : 'Add Entry'),
                    ),
                    if (_isEdit) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _viewHistory,
                        icon: const Icon(Icons.history),
                        label: const Text('View History'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final entry = HealthEntry(
        id: widget.entryId ?? '',
        petId: '',
        name: _nameController.text.trim(),
        type: _type,
        dosage: _dosageController.text.trim(),
        frequency: _frequency,
        frequencyDays: _frequency == HealthFrequency.custom
            ? int.tryParse(_customDaysController.text.trim())
            : null,
        startDate: _startDate,
        nextDueDate: _nextDueDate,
        notes: _notesController.text.trim(),
      );

      final notifier = ref.read(healthEntriesNotifierProvider.notifier);
      if (_isEdit) {
        await notifier.updateEntry(entry);
      } else {
        await notifier.create(entry);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(_isEdit ? 'Entry updated' : 'Entry created')),
        );
        context.go('/health');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _viewHistory() async {
    if (widget.entryId == null) return;

    try {
      final history = await ref
          .read(healthRepositoryProvider)
          .getHistory(widget.entryId!);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Administration History'),
          content: SizedBox(
            width: double.maxFinite,
            child: history.isEmpty
                ? const Text('No history yet.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: history.length,
                    itemBuilder: (_, i) {
                      final h = history[i];
                      return ListTile(
                        leading: const Icon(Icons.check_circle,
                            color: Colors.green),
                        title: Text(_formatDateTime(h.takenAt)),
                        subtitle: h.notes.isNotEmpty
                            ? Text(h.notes)
                            : null,
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          onChanged(DateTime(picked.year, picked.month, picked.day,
              date.hour, date.minute));
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}
