import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../providers/experience_providers.dart';

/// Guided wizard for new guardians: add first pet + first reminder.
class GuardianOnboardingScreen extends ConsumerStatefulWidget {
  const GuardianOnboardingScreen({super.key});

  @override
  ConsumerState<GuardianOnboardingScreen> createState() =>
      _GuardianOnboardingScreenState();
}

class _GuardianOnboardingScreenState
    extends ConsumerState<GuardianOnboardingScreen> {
  final _pageController = PageController();
  final _petNameController = TextEditingController();
  final _reminderNameController = TextEditingController();

  int _step = 0;
  String _species = AppConstants.species.first;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _petNameController.dispose();
    _reminderNameController.dispose();
    super.dispose();
  }

  Future<void> _skip() async {
    await ref.read(guardianOnboardingStoreProvider).markCompleted();
    if (!mounted) return;
    context.go('/g/home');
  }

  Future<void> _finish() async {
    final l = AppLocalizations.of(context)!;
    final petName = _petNameController.text.trim();
    final reminderName = _reminderNameController.text.trim();
    if (petName.isEmpty || reminderName.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final petId = await ref
          .read(petListProvider.notifier)
          .addPet(name: petName, species: _species);
      final entry = HealthEntry(
        id: const Uuid().v4(),
        petId: petId,
        name: reminderName,
        type: HealthEntryType.medication,
        frequency: HealthFrequency.monthly,
        frequencyInterval: 1,
        startDate: DateTime.now(),
        nextDueDate: _dueDate,
      );
      await ref.read(healthEntriesNotifierProvider.notifier).create(entry);
      await ref.read(guardianOnboardingStoreProvider).markCompleted();
      if (!mounted) return;
      context.go('/g/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.failedToSaveOnboarding(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _nextStep() {
    if (_step == 1 && _petNameController.text.trim().isEmpty) return;
    if (_step >= 2) {
      _finish();
      return;
    }
    setState(() => _step += 1);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      key: const Key('guardian_onboarding_screen'),
      appBar: AppBar(
        title: Text(l.guardianOnboardingTitle),
        actions: [
          TextButton(
            key: const Key('guardian_onboarding_skip'),
            onPressed: _isSaving ? null : _skip,
            child: Text(l.guardianOnboardingSkip),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_step + 1) / 3, minHeight: 4),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _WelcomeStep(
                  key: const Key('guardian_onboarding_welcome'),
                  title: l.guardianOnboardingWelcomeTitle,
                  body: l.guardianOnboardingWelcomeBody,
                ),
                _PetStep(
                  nameController: _petNameController,
                  species: _species,
                  onSpeciesChanged: (value) => setState(() => _species = value),
                ),
                _ReminderStep(
                  nameController: _reminderNameController,
                  dueDate: _dueDate,
                  onPickDate: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 5),
                      ),
                    );
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: _step == 2
                    ? const Key('guardian_onboarding_complete')
                    : const Key('guardian_onboarding_continue'),
                onPressed: _isSaving ? null : _nextStep,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _step == 0
                            ? l.guardianOnboardingGetStarted
                            : _step == 2
                            ? l.guardianOnboardingFinish
                            : l.continueButton,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PetStep extends StatelessWidget {
  const _PetStep({
    required this.nameController,
    required this.species,
    required this.onSpeciesChanged,
  });

  final TextEditingController nameController;
  final String species;
  final ValueChanged<String> onSpeciesChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l.guardianOnboardingPetStepTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(l.guardianOnboardingPetStepBody),
        const SizedBox(height: 24),
        TextField(
          key: const Key('onboarding_pet_name_field'),
          controller: nameController,
          decoration: InputDecoration(
            labelText: l.petName,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: const Key('onboarding_pet_species_field'),
          value: species,
          decoration: InputDecoration(
            labelText: l.species,
            border: const OutlineInputBorder(),
          ),
          items: AppConstants.species
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (value) {
            if (value != null) onSpeciesChanged(value);
          },
        ),
      ],
    );
  }
}

class _ReminderStep extends StatelessWidget {
  const _ReminderStep({
    required this.nameController,
    required this.dueDate,
    required this.onPickDate,
  });

  final TextEditingController nameController;
  final DateTime dueDate;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l.guardianOnboardingReminderStepTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(l.guardianOnboardingReminderStepBody),
        const SizedBox(height: 24),
        TextField(
          key: const Key('onboarding_reminder_name_field'),
          controller: nameController,
          decoration: InputDecoration(
            labelText: l.guardianOnboardingReminderNameLabel,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 16),
        ListTile(
          key: const Key('onboarding_reminder_due_date'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.nextDueDate),
          subtitle: Text(DateFormat.yMMMd().format(dueDate)),
          trailing: const Icon(Icons.calendar_today),
          onTap: onPickDate,
        ),
      ],
    );
  }
}
