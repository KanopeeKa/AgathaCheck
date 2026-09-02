// Shared test infrastructure for guardian events list tests.
//
// Imported by guardian_due_events_screen_test.dart and
// global_events_list_actions_test.dart to avoid duplication.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/add_event_type_picker_sheet.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_due_events_screen.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/experience_shell_scaffold.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_history_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/occurrence_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/fakes.dart';

export 'package:flutter_test/flutter_test.dart';
export 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_due_events_screen.dart';
export 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
export 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
export 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
export 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
export '../../../../../helpers/fakes.dart';

// ---------------------------------------------------------------------------
// Shared notifiers
// ---------------------------------------------------------------------------

class TestFixedEntriesNotifier extends HealthEntriesNotifier {
  TestFixedEntriesNotifier(this._entries);
  final List<HealthEntry> _entries;

  @override
  Future<List<HealthEntry>> build() async => _entries;
}

/// Server-like: markTaken removes the entry; undoComplete restores it.
class TestServerLikeNotifier extends HealthEntriesNotifier {
  TestServerLikeNotifier(this._initial);
  final List<HealthEntry> _initial;
  int undoCalls = 0;
  String? lastUndoId;

  @override
  Future<List<HealthEntry>> build() async => List<HealthEntry>.from(_initial);

  @override
  Future<void> markTaken(
    String id, {
    String notes = '',
    DateTime? completedOn,
  }) async {
    final current = state.valueOrNull ?? _initial;
    state = AsyncValue.data(current.where((e) => e.id != id).toList());
  }

  @override
  Future<void> undoComplete(String id) async {
    undoCalls++;
    lastUndoId = id;
    final current = state.valueOrNull ?? const <HealthEntry>[];
    if (!current.any((e) => e.id == id)) {
      final restored = _initial.firstWhere((e) => e.id == id);
      state = AsyncValue.data([...current, restored]);
    }
  }
}

class TestFailingMarkTakenNotifier extends HealthEntriesNotifier {
  TestFailingMarkTakenNotifier(this._initial);
  final List<HealthEntry> _initial;

  @override
  Future<List<HealthEntry>> build() async => List<HealthEntry>.from(_initial);

  @override
  Future<void> markTaken(
    String id, {
    String notes = '',
    DateTime? completedOn,
  }) async => throw StateError('server rejected completion');
}

/// Completes entries successfully, but undoComplete always fails.
class TestFailingUndoNotifier extends HealthEntriesNotifier {
  TestFailingUndoNotifier(this._initial);
  final List<HealthEntry> _initial;

  @override
  Future<List<HealthEntry>> build() async => List<HealthEntry>.from(_initial);

  @override
  Future<void> markTaken(
    String id, {
    String notes = '',
    DateTime? completedOn,
  }) async {
    final current = state.valueOrNull ?? _initial;
    state = AsyncValue.data(current.where((e) => e.id != id).toList());
  }

  @override
  Future<void> undoComplete(String id) async =>
      throw StateError('server rejected undo');
}

class TestErrorEntriesNotifier extends HealthEntriesNotifier {
  @override
  Future<List<HealthEntry>> build() async => throw StateError('unavailable');
}

class TestMutableEntriesNotifier extends HealthEntriesNotifier {
  TestMutableEntriesNotifier(this._initial);
  final List<HealthEntry> _initial;

  @override
  Future<List<HealthEntry>> build() async => List<HealthEntry>.from(_initial);

  void publishTerminalError() {
    state = AsyncValue.error(StateError('unavailable'), StackTrace.current);
  }
}

class TestErrorPetListNotifier extends PetListNotifier {
  @override
  Future<List<Pet>> build() async => throw StateError('pets unavailable');
}

// ---------------------------------------------------------------------------
// Shared test data
// ---------------------------------------------------------------------------

const testOwnedPet = Pet(
  id: 'pet-owned',
  name: 'Rex',
  species: 'Dog',
  breed: '',
);
const testFosterPet = Pet(
  id: 'pet-foster',
  name: 'Luna',
  species: 'Cat',
  breed: '',
  isFoster: true,
);
const testSharedPet = Pet(
  id: 'pet-shared',
  name: 'Milo',
  species: 'Dog',
  breed: '',
  isShared: true,
);

final testAllShellPets = [testOwnedPet, testFosterPet, testSharedPet];

HealthEntry makeDueEntry({
  String id = 'entry-due',
  String petId = 'pet-owned',
  String name = 'Morning walk',
  DateTime? nextDueDate,
}) => HealthEntry(
  id: id,
  petId: petId,
  name: name,
  type: HealthEntryType.other,
  dosage: '',
  frequency: HealthFrequency.daily,
  startDate: DateTime(2025, 1, 1),
  nextDueDate: nextDueDate ?? DateTime.now(),
);

// ---------------------------------------------------------------------------
// History stub
// ---------------------------------------------------------------------------

Future<List<HealthHistoryEntry>> stubHistory(Ref ref, String entryId) async =>
    [];

Future<List<HealthOccurrence>> stubOpenOccurrences(
  Ref ref,
  String entryId,
) async => [];

List<Override> get guardianEventsTestOverrides => [
  entryOccurrencesProvider.overrideWith(stubOpenOccurrences),
  entryHistoryProvider.overrideWith(stubHistory),
];

// ---------------------------------------------------------------------------
// Widget builders
// ---------------------------------------------------------------------------

/// Full shell-scaffold screen builder (for picker / filter tests).
Widget buildEventsScreen({
  List<HealthEntry>? entries,
  HealthEntriesNotifier Function()? notifierFactory,
  List<Pet>? shellPets,
}) {
  final pets = shellPets ?? testAllShellPets;
  final router = GoRouter(
    initialLocation: '/g/events',
    routes: [
      GoRoute(
        path: '/g/events',
        builder: (context, state) => ExperienceShellScaffold(
          experience: AppExperience.guardian,
          currentLocation: state.uri.path,
          screenTitle: 'Events',
          backPath: '/g/home',
          contextualActions: [
            Builder(
              builder: (ctx) => IconButton(
                key: const Key('global_events_add_app_bar'),
                onPressed: () => showAddEventTypePickerSheet(ctx, pets: pets),
                icon: const Icon(Icons.add),
              ),
            ),
          ],
          child: const GuardianDueEventsScreen(),
        ),
      ),
      GoRoute(
        path: '/health/add',
        builder: (_, __) => const Scaffold(body: Text('Add health entry')),
      ),
      GoRoute(
        path: '/pet/:petId/events/:entryId',
        builder: (_, state) => Scaffold(
          body: Center(child: Text('View ${state.pathParameters['entryId']}')),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      petListProvider.overrideWith(() => TestPetListNotifier(pets)),
      healthEntriesNotifierProvider.overrideWith(
        notifierFactory ??
            () => TestFixedEntriesNotifier(entries ?? _defaultEntries),
      ),
      ...guardianEventsTestOverrides,
    ],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme.copyWith(
        splashFactory: NoSplash.splashFactory,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

/// Bare [GlobalEventsList] widget (no router) — for layout/action tests.
Widget buildListScreen({
  required List<Pet> pets,
  required HealthEntriesNotifier Function() notifierFactory,
}) {
  return ProviderScope(
    overrides: [
      petListProvider.overrideWith(() => TestPetListNotifier(pets)),
      healthEntriesNotifierProvider.overrideWith(notifierFactory),
      ...guardianEventsTestOverrides,
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme.copyWith(
        splashFactory: NoSplash.splashFactory,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: GlobalEventsList(shellPets: pets)),
    ),
  );
}

/// [GuardianDueEventsScreen] with a pet-provider that errors — tests pet-load
/// error recovery UI.
Widget buildScreenWithPetError() {
  return ProviderScope(
    overrides: [
      petListProvider.overrideWith(TestErrorPetListNotifier.new),
      healthEntriesNotifierProvider.overrideWith(TestErrorEntriesNotifier.new),
      ...guardianEventsTestOverrides,
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme.copyWith(
        splashFactory: NoSplash.splashFactory,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: GuardianDueEventsScreen()),
    ),
  );
}

// ---------------------------------------------------------------------------
// Private default entries
// ---------------------------------------------------------------------------

final _ownedDefaultEntry = HealthEntry(
  id: 'entry-owned',
  petId: 'pet-owned',
  name: 'Heartgard',
  type: HealthEntryType.medication,
  dosage: '1 tablet',
  frequency: HealthFrequency.monthly,
  startDate: DateTime(2025, 1, 1),
  nextDueDate: DateTime.now().add(const Duration(days: 3)),
);

final _fosterDefaultEntry = HealthEntry(
  id: 'entry-foster',
  petId: 'pet-foster',
  name: 'Flea treatment',
  type: HealthEntryType.preventive,
  dosage: '',
  frequency: HealthFrequency.monthly,
  startDate: DateTime(2025, 1, 1),
  nextDueDate: DateTime.now().subtract(const Duration(days: 2)),
);

final _sharedDefaultEntry = HealthEntry(
  id: 'entry-shared',
  petId: 'pet-shared',
  name: 'Grooming',
  type: HealthEntryType.other,
  dosage: 'Full groom',
  frequency: HealthFrequency.once,
  startDate: DateTime(2025, 1, 1),
  completedOn: DateTime(2025, 3, 1),
  nextDueDate: DateTime(9999, 12, 31),
);

final _defaultEntries = [
  _ownedDefaultEntry,
  _fosterDefaultEntry,
  _sharedDefaultEntry,
];
