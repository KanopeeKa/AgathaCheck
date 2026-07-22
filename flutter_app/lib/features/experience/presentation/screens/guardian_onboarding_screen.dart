import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../providers/experience_providers.dart';

/// Guided wizard for new guardians: add first pet.
class GuardianOnboardingScreen extends ConsumerStatefulWidget {
  const GuardianOnboardingScreen({super.key});

  @override
  ConsumerState<GuardianOnboardingScreen> createState() =>
      _GuardianOnboardingScreenState();
}

class _GuardianOnboardingScreenState
    extends ConsumerState<GuardianOnboardingScreen> {
  static const _stepCount = 2;

  final _pageController = PageController();
  final _petNameController = TextEditingController();

  int _step = 0;
  String _species = AppConstants.species.first;
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _petNameController.dispose();
    super.dispose();
  }

  Future<void> _persistOnboardingComplete() async {
    await ref.read(guardianOnboardingStoreProvider).markCompleted();
    ref.invalidate(guardianOnboardingCompletedProvider);
  }

  Future<void> _skip() async {
    await _persistOnboardingComplete();
    if (!mounted) return;
    context.go('/g/home');
  }

  Future<void> _finish() async {
    final l = AppLocalizations.of(context)!;
    final petName = _petNameController.text.trim();
    if (petName.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(petListProvider.notifier)
          .addPet(name: petName, species: _species);
      await _persistOnboardingComplete();
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
    if (_step >= 1) {
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
          LinearProgressIndicator(value: (_step + 1) / _stepCount, minHeight: 4),
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: _step == 1
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
                            : l.guardianOnboardingFinish,
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
          textInputAction: TextInputAction.done,
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
