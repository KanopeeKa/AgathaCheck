import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/providers/http_client_provider.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/sharing_providers.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../widgets/shared_pet_profile_card.dart';
import '../widgets/shared_pet_accept_section.dart';
import '../widgets/shared_pet_owner_card.dart';
import '../widgets/shared_pet_vet_card.dart';
import '../widgets/shared_pet_health_entry_card.dart';

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
  Map<String, dynamic>? _ownerData;
  bool _loading = true;
  String? _error;
  bool _accepting = false;

  // Use the shared base URL ('/backend' on web) for consistency with the rest
  // of the app rather than a hardcoded prefix.
  String get _baseUrl => ref.read(apiBaseUrlProvider);

  @override
  void initState() {
    super.initState();
    _loadSharedPet();
  }

  Future<void> _loadSharedPet() async {
    try {
      final client = ref.read(httpClientProvider);
      final response = await client.get(
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
          _ownerData = data['owner'] as Map<String, dynamic>?;
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
    final l = AppLocalizations.of(context)!;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _petData == null) {
      return Scaffold(
        appBar: AppBar(title: const AppLogoTitle(title: 'Shared Pet')),
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
    final dobStr = (pet['dateOfBirth'] ?? pet['date_of_birth']) as String?;
    final dateOfBirth = dobStr != null ? DateTime.tryParse(dobStr) : null;
    String? ageDisplay;
    if (dateOfBirth != null) {
      final diff = DateTime.now().difference(dateOfBirth).inDays / 365.25;
      if (diff < 1) {
        final months = (diff * 12).round();
        ageDisplay = months <= 1 ? '1 month' : '$months months';
      } else {
        ageDisplay = '${diff.toStringAsFixed(1)} yrs';
      }
    }
    final weight = (pet['weight'] as num?)?.toDouble();
    final bio = pet['bio'] as String? ?? '';
    final photoPath = pet['photoPath'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: name),
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Go to My Pets',
          onPressed: () => context.go('/'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ExcludeSemantics(
              child: Chip(
                avatar: Icon(Icons.visibility, size: 16,
                    color: colorScheme.onSecondaryContainer),
                label: Text(l.viewOnly,
                    style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSecondaryContainer)),
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
            name: name,
            species: species,
            breed: breed,
            ageDisplay: ageDisplay,
            weight: weight,
            vetName: _vetData != null ? _vetData!['name'] as String? : null,
            bio: bio,
            photoPath: photoPath,
            colorScheme: colorScheme,
            theme: theme,
            buildPhoto: _buildPhoto,
            buildChip: _buildChip,
          ),

          const SizedBox(height: 16),
          SharedPetAcceptSection(
            isLoggedIn: ref.watch(authProvider).isLoggedIn,
            accepting: _accepting,
            onAccept: () async {
              setState(() => _accepting = true);
              try {
                final repo = ref.read(sharingRepositoryProvider);
                final token = await ref.read(authProvider.notifier).getValidAccessToken();
                if (token == null) return;
                await repo.acceptShare(widget.shareCode, token);
                ref.invalidate(allPetsIncludingOrgProvider);
                await ref.read(allPetsIncludingOrgProvider.future);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.shareAccepted)),
                );
                context.go('/');
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: \\${e.toString().replaceFirst("Exception: ", "")}')),
                );
              } finally {
                if (mounted) setState(() => _accepting = false);
              }
            },
            theme: theme,
            colorScheme: colorScheme,
            promptText: 'Want to add this pet to your account?',
            buttonText: _accepting ? 'Adding...' : l.acceptAndAdd,
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

          if (_vetData != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.local_hospital, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(l.veterinarians, style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            SharedPetVetCard(
              vetData: _vetData!,
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.list_alt, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(l.events, style: theme.textTheme.titleLarge),
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
                      Text(l.noEntriesYet,
                          style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._healthEntries.map((e) => SharedPetHealthEntryCard(
                  entry: e,
                  theme: theme,
                  colorScheme: colorScheme,
                )),
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

}
