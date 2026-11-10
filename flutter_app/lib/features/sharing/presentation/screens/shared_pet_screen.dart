import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../core/widgets/invite_recipient_block.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/features/auth/auth.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import '../../data/datasources/sharing_remote_datasource.dart';
import '../providers/sharing_providers.dart';
import '../widgets/shared_pet_accept_section.dart';
import '../widgets/shared_pet_owner_card.dart';
import '../widgets/shared_pet_profile_card.dart';

class SharedPetScreen extends ConsumerStatefulWidget {
  const SharedPetScreen({super.key, required this.shareCode});

  final String shareCode;

  @override
  ConsumerState<SharedPetScreen> createState() => _SharedPetScreenState();
}

class _SharedPetScreenState extends ConsumerState<SharedPetScreen> {
  Map<String, dynamic>? _petData;
  Map<String, dynamic>? _ownerData;
  bool _loading = true;
  String? _errorKey;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _loadSharedPet();
  }

  Future<void> _loadSharedPet() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorKey = null;
      _petData = null;
      _ownerData = null;
    });
    try {
      final repo = ref.read(sharingRepositoryProvider);
      final preview = await repo.getSharePreview(widget.shareCode);
      if (!mounted) return;
      setState(() {
        _petData = preview.pet;
        _ownerData = preview.owner;
        _loading = false;
      });
    } on SharePreviewExpiredException {
      if (!mounted) return;
      setState(() {
        _errorKey = 'expired';
        _loading = false;
      });
    } on SharePreviewNotFoundException {
      if (!mounted) return;
      setState(() {
        _errorKey = 'not_found';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorKey = 'load_failed';
        _loading = false;
      });
    }
  }

  String? _ageDisplay(BuildContext context, Map<String, dynamic> pet) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final dobStr = (pet['dateOfBirth'] ?? pet['date_of_birth']) as String?;
    final dateOfBirth = parseCalendarDate(dobStr);
    if (dateOfBirth != null) {
      final diff = DateTime.now().difference(dateOfBirth).inDays / 365.25;
      if (diff < 1) {
        final months = (diff * 12).round().clamp(1, 11);
        return l.sharedPetAgeMonths(months);
      }
      if (diff >= 0.95 && diff < 1.5) {
        return l.sharedPetAgeYearsOne;
      }
      final years = NumberFormat.decimalPattern(locale).format(
        double.parse(diff.toStringAsFixed(1)),
      );
      return l.sharedPetAgeYearsFormatted(years);
    }
    if (pet['age'] != null) {
      final ageNum = pet['age'];
      final ageDouble =
          ageNum is num ? ageNum.toDouble() : double.tryParse('$ageNum') ?? 0;
      if (ageDouble >= 0.95 && ageDouble < 1.5) {
        return l.sharedPetAgeYearsOne;
      }
      final years = NumberFormat.decimalPattern(locale).format(ageDouble);
      return l.sharedPetAgeYearsFormatted(years);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorKey != null || _petData == null) {
      if (_errorKey == 'load_failed') {
        return Scaffold(
          appBar: AppBar(title: AppLogoTitle(title: l.sharedPetTitle)),
          body: AsyncErrorState(
            title: l.sharedPetLoadFailed,
            onRetry: _loadSharedPet,
          ),
        );
      }
      final errorMessage = switch (_errorKey) {
        'expired' => l.sharedPetNotFound,
        'not_found' => l.sharedPetNotFound,
        _ => l.sharedPetNotFound,
      };
      return Scaffold(
        appBar: AppBar(title: AppLogoTitle(title: l.sharedPetTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link_off, size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(errorMessage, style: theme.textTheme.titleMedium),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: Text(l.goToPetCare),
              ),
            ],
          ),
        ),
      );
    }

    final pet = _petData!;
    final name = (pet['name'] as String?)?.trim();
    final displayName =
        (name != null && name.isNotEmpty) ? name : l.unknownPet;
    final species = pet['species'] as String? ?? '';
    final breed = pet['breed'] as String? ?? '';
    final ageDisplay = _ageDisplay(context, pet);
    final photoPath = (pet['photoPath'] ?? pet['photo_path']) as String?;
    final inviterFirst = _ownerData?['first_name'] as String?;
    final invitePath = '/shared/${widget.shareCode}';

    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: displayName),
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: l.goToPetCare,
          onPressed: () => context.go('/'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              identifier: 'view_only_badge',
              label: l.viewOnly,
              child: Chip(
                avatar: Icon(
                  Icons.visibility,
                  size: 16,
                  color: colorScheme.onSecondaryContainer,
                ),
                label: Text(
                  l.viewOnly,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                backgroundColor: colorScheme.secondaryContainer,
                side: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SharedPetProfileCard(
            name: displayName,
            species: species,
            breed: breed,
            ageDisplay: ageDisplay,
            weight: null,
            vetName: null,
            bio: '',
            photoPath: photoPath,
            colorScheme: colorScheme,
            theme: theme,
            buildPhoto: _buildPhoto,
            buildChip: _buildChip,
          ),
          const SizedBox(height: 16),
          SharedPetAcceptSection(
            isLoggedIn: isLoggedIn,
            accepting: _accepting,
            onAccept: () async {
              setState(() => _accepting = true);
              try {
                final repo = ref.read(sharingRepositoryProvider);
                final token = await ref
                    .read(authProvider.notifier)
                    .getValidAccessToken();
                if (token == null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.shareAcceptFailed)),
                  );
                  return;
                }
                await repo.acceptShare(widget.shareCode, token);
                ref.invalidate(allPetsIncludingOrgProvider);
                await ref.read(allPetsIncludingOrgProvider.future);
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l.shareAccepted)));
                context.go('/');
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.shareAcceptFailed)),
                );
              } finally {
                if (mounted) setState(() => _accepting = false);
              }
            },
            theme: theme,
            colorScheme: colorScheme,
            promptText: l.sharedPetAcceptPrompt,
            buttonText: _accepting ? l.sharedPetAdding : l.acceptAndAdd,
            invitePath: invitePath,
            inviterName: inviterFirst,
            petsSummary: displayName,
            scopeDescription: l.viewOnly,
          ),
          if (_ownerData != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.person, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(l.sharedBy, style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            SharedPetOwnerCard(
              ownerData: _ownerData!,
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],
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
        child: Icon(
          Icons.pets,
          size: 56,
          color: colorScheme.onPrimaryContainer.withAlpha(100),
        ),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
