import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../vet/presentation/providers/vet_providers.dart';
import '../../../weight_tracking/presentation/providers/weight_providers.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_providers.dart';
import 'widgets/chip_reminder_card.dart';
import 'widgets/download_report_section.dart';
import 'widgets/family_events_section.dart';
import 'widgets/health_events_section.dart';
import 'widgets/health_issues_section.dart';
import 'widgets/neuter_reminder_card.dart';
import 'widgets/sharing_section.dart';
import 'widgets/weight_tracking_section.dart';

class PetDetailScreen extends ConsumerStatefulWidget {
  const PetDetailScreen({super.key, required this.petId});

  final String petId;

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {

  @override
  Widget build(BuildContext context) {
    final petListAsync = ref.watch(allPetsIncludingOrgProvider);
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
                  child: NeuterReminderCard(pet: pet),
                ),
              if (pet.chipId.isEmpty && !pet.chipDismissed)
                SliverToBoxAdapter(
                  child: ChipReminderCard(pet: pet),
                ),
              SliverToBoxAdapter(
                child: WeightTrackingSection(petId: widget.petId),
              ),
              SliverToBoxAdapter(
                child: HealthIssuesSection(petId: widget.petId, pet: pet),
              ),
              SliverToBoxAdapter(
                child: HealthEventsSection(petId: widget.petId, pet: pet),
              ),
              if (pet.organizationId != null)
                SliverToBoxAdapter(
                  child: FamilyEventsSection(petId: widget.petId, pet: pet),
                ),
              if (!pet.isShared)
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
