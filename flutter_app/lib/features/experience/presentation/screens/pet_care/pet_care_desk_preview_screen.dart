import 'package:flutter/material.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../core/widgets/dashboard_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import 'pet_care_my_pets_section.dart';
import '../../widgets/pet_care_operations_desk_layout.dart';

/// Development-only visual review route for the Guardian Operations Desk.
///
/// It deliberately uses synthetic pets and local generated portraits so that
/// no account data is shown while refining the dashboard skin.
class PetCareDeskPreviewScreen extends StatelessWidget {
  const PetCareDeskPreviewScreen({super.key});

  static const _previewPets = <Pet>[
    Pet(
      id: 'preview-juniper',
      name: 'Juniper',
      species: 'Dog',
      breed: 'Border Collie',
      photoPath: 'asset://assets/demo_pets/juniper.jpg',
      colorValue: 0xFF3F6250,
    ),
    Pet(
      id: 'preview-saffron',
      name: 'Saffron',
      species: 'Cat',
      breed: 'Domestic Shorthair',
      photoPath: 'asset://assets/demo_pets/saffron.jpg',
      colorValue: 0xFFC9A65A,
    ),
    Pet(
      id: 'preview-orbit',
      name: 'Orbit',
      species: 'Dog',
      breed: 'Whippet',
      colorValue: 0xFF718173,
    ),
    Pet(
      id: 'preview-moss',
      name: 'Moss',
      species: 'Dog',
      breed: 'Greyhound',
      photoPath: 'asset://assets/demo_pets/moss.jpg',
      isFoster: true,
      organizationId: 'preview-shelter',
      organizationName: 'Harbour Rescue',
      fosterName: 'Sam',
      colorValue: 0xFF6F855C,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final deskTheme = _previewDeskTheme(theme);

    return Theme(
      data: deskTheme,
      child: Scaffold(
        backgroundColor: AppColorTokens.operationsDeskCanvas,
        appBar: AppBar(
          backgroundColor: AppColorTokens.operationsSurface,
          surfaceTintColor: Colors.transparent,
          title: Text(
            l10n.myPets,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColorTokens.operationsInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return ColoredBox(
              color: AppColorTokens.operationsDeskCanvas,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: PetCareOperationsDeskLayout(
                  useWideLayout:
                      constraints.maxWidth >=
                      PetCareOperationsDeskLayout.wideBreakpoint,
                  petsSection: PetCareMyPetsSection(
                    allPets: _previewPets,
                    controller: PetListController(),
                    previewPets: _previewPets,
                    previewOverflowCount: 0,
                  ),
                  eventsSection: _PreviewDeskSection(
                    title: l10n.dueAndOverdue,
                    rows: const [
                      _PreviewRow(
                        icon: Icons.medication_outlined,
                        label: 'Moss · flea treatment',
                        detail: 'Due today',
                      ),
                      _PreviewRow(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Juniper · weight check',
                        detail: 'Tomorrow',
                      ),
                    ],
                  ),
                  vetsSection: _PreviewDeskSection(
                    title: l10n.myVets,
                    rows: const [
                      _PreviewRow(
                        icon: Icons.local_hospital_outlined,
                        label: 'Harbour Veterinary Practice',
                        detail: '3 pets connected',
                      ),
                      _PreviewRow(
                        icon: Icons.local_hospital_outlined,
                        label: 'Northside Emergency Clinic',
                        detail: '1 pet connected',
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  ThemeData _previewDeskTheme(ThemeData theme) {
    return theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        primary: AppColorTokens.petCareCarePrimary,
        onPrimary: AppColorTokens.inverse,
        primaryContainer: AppColorTokens.operationsPaper,
        onPrimaryContainer: AppColorTokens.petCareCareActive,
        surface: AppColorTokens.operationsSurface,
        onSurface: AppColorTokens.operationsInk,
        surfaceContainerHighest: AppColorTokens.operationsPaper,
        outlineVariant: AppColorTokens.operationsOlive.withValues(alpha: 0.18),
      ),
      cardTheme: theme.cardTheme.copyWith(
        color: AppColorTokens.operationsSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorTokens.petCareCarePrimary,
          minimumSize: const Size(48, 48),
        ),
      ),
    );
  }
}

class _PreviewDeskSection extends StatelessWidget {
  const _PreviewDeskSection({required this.title, required this.rows});

  final String title;
  final List<_PreviewRow> rows;

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: title,
      previewBuilder: (context) {
        return Column(
          children: rows
              .map(
                (row) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    row.icon,
                    color: AppColorTokens.petCareCarePrimary,
                  ),
                  title: Text(row.label),
                  subtitle: Text(row.detail),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _PreviewRow {
  const _PreviewRow({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;
}
