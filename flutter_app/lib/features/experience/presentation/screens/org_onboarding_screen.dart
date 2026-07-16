import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../organization/domain/entities/organization.dart';
import '../../../organization/presentation/providers/organization_providers.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../providers/experience_providers.dart';

/// Guided wizard for org super-admins: create org, first inventory pet, reminder.
class OrgOnboardingScreen extends ConsumerStatefulWidget {
  const OrgOnboardingScreen({super.key});

  @override
  ConsumerState<OrgOnboardingScreen> createState() =>
      _OrgOnboardingScreenState();
}

class _OrgOnboardingScreenState extends ConsumerState<OrgOnboardingScreen> {
  final _pageController = PageController();
  final _orgNameController = TextEditingController();
  final _petNameController = TextEditingController();
  final _reminderNameController = TextEditingController();

  int _step = 0;
  bool _needsOrgStep = true;
  String? _orgId;
  OrganizationType _orgType = OrganizationType.charity;
  String _species = AppConstants.species.first;
  DateTime _dueDate = calendarDateOnly(
    DateTime.now().add(const Duration(days: 7)),
  );
  bool _isSaving = false;

  int get _totalSteps => _needsOrgStep ? 4 : 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orgs = ref.read(organizationListProvider).valueOrNull ?? [];
      if (!mounted) return;
      setState(() {
        _needsOrgStep = orgs.isEmpty;
        if (orgs.isNotEmpty) _orgId = orgs.first.id;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _orgNameController.dispose();
    _petNameController.dispose();
    _reminderNameController.dispose();
    super.dispose();
  }

  Future<void> _persistOnboardingComplete() async {
    await ref.read(orgOnboardingStoreProvider).markCompleted();
    ref.invalidate(orgOnboardingCompletedProvider);
  }

  Future<void> _skip() async {
    await _persistOnboardingComplete();
    if (!mounted) return;
    context.go('/o/home');
  }

  Future<void> _finish() async {
    final l = AppLocalizations.of(context)!;
    final petName = _petNameController.text.trim();
    final reminderName = _reminderNameController.text.trim();
    if (petName.isEmpty || reminderName.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      var orgId = _orgId;
      if (_needsOrgStep) {
        final org = await ref
            .read(organizationListProvider.notifier)
            .createOrganization({
              'name': _orgNameController.text.trim(),
              'type': _orgType == OrganizationType.charity
                  ? 'charity'
                  : 'professional',
            });
        orgId = org.id;
      }
      if (orgId == null || orgId.isEmpty) {
        throw StateError('Organization is required to add an inventory pet');
      }

      final petId = await ref
          .read(petListProvider.notifier)
          .addPet(name: petName, species: _species, organizationId: orgId);
      final entry = HealthEntry(
        id: const Uuid().v4(),
        petId: petId,
        name: reminderName,
        type: HealthEntryType.medication,
        frequency: HealthFrequency.monthly,
        frequencyInterval: 1,
        startDate: calendarDateOnly(DateTime.now()),
        nextDueDate: calendarDateOnly(_dueDate),
      );
      await ref.read(healthEntriesNotifierProvider.notifier).create(entry);
      await _persistOnboardingComplete();
      if (!mounted) return;
      context.go('/o/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.failedToSaveOnboarding(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _validateCurrentStep() {
    if (_step == 0) return true;
    if (_needsOrgStep) {
      if (_step == 1) return _orgNameController.text.trim().isNotEmpty;
      if (_step == 2) return _petNameController.text.trim().isNotEmpty;
      if (_step == 3) return _reminderNameController.text.trim().isNotEmpty;
    } else {
      if (_step == 1) return _petNameController.text.trim().isNotEmpty;
      if (_step == 2) return _reminderNameController.text.trim().isNotEmpty;
    }
    return true;
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_step >= _totalSteps - 1) {
      _finish();
      return;
    }
    setState(() => _step += 1);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  String _primaryButtonLabel(AppLocalizations l) {
    if (_step == 0) return l.orgOnboardingGetStarted;
    if (_step >= _totalSteps - 1) return l.orgOnboardingFinish;
    return l.continueButton;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pages = <Widget>[
      _WelcomeStep(
        key: const Key('org_onboarding_welcome'),
        title: l.orgOnboardingWelcomeTitle,
        body: l.orgOnboardingWelcomeBody,
      ),
      if (_needsOrgStep)
        _OrgStep(
          nameController: _orgNameController,
          orgType: _orgType,
          onTypeChanged: (value) => setState(() => _orgType = value),
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
          final today = calendarDateOnly(DateTime.now());
          final picked = await showDatePicker(
            context: context,
            initialDate: calendarDateOnly(_dueDate),
            firstDate: today,
            lastDate: calendarDateOnly(
              today.add(const Duration(days: 365 * 5)),
            ),
          );
          if (picked != null) {
            setState(() => _dueDate = calendarDateOnly(picked));
          }
        },
      ),
    ];

    return Scaffold(
      key: const Key('org_onboarding_screen'),
      appBar: AppBar(
        title: Text(l.orgOnboardingTitle),
        actions: [
          TextButton(
            key: const Key('org_onboarding_skip'),
            onPressed: _isSaving ? null : _skip,
            child: Text(l.orgOnboardingSkip),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_step + 1) / _totalSteps,
            minHeight: 4,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: pages,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: _step >= _totalSteps - 1
                    ? const Key('org_onboarding_complete')
                    : const Key('org_onboarding_continue'),
                onPressed: _isSaving ? null : _nextStep,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_primaryButtonLabel(l)),
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
          Icon(Icons.business, size: 72, color: theme.colorScheme.primary),
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

class _OrgStep extends StatelessWidget {
  const _OrgStep({
    required this.nameController,
    required this.orgType,
    required this.onTypeChanged,
  });

  final TextEditingController nameController;
  final OrganizationType orgType;
  final ValueChanged<OrganizationType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l.orgOnboardingOrgStepTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(l.orgOnboardingOrgStepBody),
        const SizedBox(height: 24),
        TextField(
          key: const Key('onboarding_org_name_field'),
          controller: nameController,
          decoration: InputDecoration(
            labelText: l.organizationName,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<OrganizationType>(
          key: const Key('onboarding_org_type_field'),
          value: orgType,
          decoration: InputDecoration(
            labelText: l.organizationType,
            border: const OutlineInputBorder(),
          ),
          items: OrganizationType.values
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(
                    type == OrganizationType.charity
                        ? l.orgTypeCharity
                        : l.orgTypeProfessional,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onTypeChanged(value);
          },
        ),
      ],
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
          l.orgOnboardingPetStepTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(l.orgOnboardingPetStepBody),
        const SizedBox(height: 24),
        TextField(
          key: const Key('onboarding_org_pet_name_field'),
          controller: nameController,
          decoration: InputDecoration(
            labelText: l.petName,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: const Key('onboarding_org_pet_species_field'),
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
          l.orgOnboardingReminderStepTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(l.orgOnboardingReminderStepBody),
        const SizedBox(height: 24),
        TextField(
          key: const Key('onboarding_org_reminder_name_field'),
          controller: nameController,
          decoration: InputDecoration(
            labelText: l.guardianOnboardingReminderNameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          key: const Key('onboarding_org_reminder_due_date'),
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
