import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_dashboard_helpers.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_full_list_pet_card.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  Widget buildCard(
    Pet pet, {
    GuardianTodayPetCareState careState = GuardianTodayPetCareState.clear,
    VoidCallback? onTap,
    double cardWidth = 360,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: cardWidth,
            child: GuardianFullListPetCard(
              pet: pet,
              careState: careState,
              onTap: onTap ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  // ── ownership labels are derived from Pet fields, not visual state ──────────

  testWidgets('shows My Pets label for a guardian-owned pet', (tester) async {
    const pet = Pet(id: 'miso', name: 'Miso', species: 'Cat');
    await tester.pumpWidget(buildCard(pet));
    await tester.pump();

    expect(find.text('My Pets'), findsOneWidget);
    expect(find.text('Miso'), findsOneWidget);
  });

  testWidgets('shows Shared Pets label for a shared pet', (tester) async {
    const pet = Pet(id: 'luna', name: 'Luna', species: 'Dog', isShared: true);
    await tester.pumpWidget(buildCard(pet));
    await tester.pump();

    expect(find.text('Shared Pets'), findsOneWidget);
  });

  testWidgets('shows My Fostered Pets label for a fostered pet', (
    tester,
  ) async {
    const pet = Pet(
      id: 'rex',
      name: 'Rex',
      species: 'Dog',
      isFoster: true,
      organizationName: 'Happy Paws',
    );
    await tester.pumpWidget(buildCard(pet));
    await tester.pump();

    expect(find.text('My Fostered Pets'), findsOneWidget);
  });

  // ── care urgency badge — separate signal from ownership/lifecycle ────────────

  testWidgets('shows overdue badge for an overdue care state', (tester) async {
    const pet = Pet(id: 'bolt', name: 'Bolt', species: 'Dog');
    await tester.pumpWidget(
      buildCard(pet, careState: GuardianTodayPetCareState.overdue),
    );
    await tester.pump();

    expect(find.text('Overdue'), findsOneWidget);
    // must NOT also show a passed-away label
    expect(find.text('Passed Away'), findsNothing);
  });

  testWidgets('shows due-today badge for dueToday care state', (tester) async {
    const pet = Pet(id: 'bolt', name: 'Bolt', species: 'Dog');
    await tester.pumpWidget(
      buildCard(pet, careState: GuardianTodayPetCareState.dueToday),
    );
    await tester.pump();

    expect(find.text('Due today'), findsOneWidget);
  });

  testWidgets('shows all-clear badge for clear care state', (tester) async {
    const pet = Pet(id: 'bolt', name: 'Bolt', species: 'Dog');
    await tester.pumpWidget(
      buildCard(pet, careState: GuardianTodayPetCareState.clear),
    );
    await tester.pump();

    expect(find.text('All clear'), findsOneWidget);
  });

  // ── lifecycle status — passed-away overrides care badge ─────────────────────

  testWidgets('shows Passed Away lifecycle badge and suppresses care badge', (
    tester,
  ) async {
    const pet = Pet(
      id: 'memorial',
      name: 'Buddy',
      species: 'Dog',
      passedAway: true,
    );
    await tester.pumpWidget(
      buildCard(pet, careState: GuardianTodayPetCareState.overdue),
    );
    await tester.pump();

    expect(find.text('Passed Away'), findsOneWidget);
    // Care urgency must be suppressed for passed-away pets
    expect(find.text('Overdue'), findsNothing);
  });

  // ── semantics label encodes ownership, lifecycle, and care as separate fields

  testWidgets('semantics label encodes pet name, ownership and care state', (
    tester,
  ) async {
    const pet = Pet(id: 'miso', name: 'Miso', species: 'Cat');
    await tester.pumpWidget(
      buildCard(pet, careState: GuardianTodayPetCareState.upcoming),
    );
    await tester.pump();

    expect(
      find.bySemanticsLabel('Miso, My Pets, Care coming up'),
      findsOneWidget,
    );
  });

  testWidgets('semantics label uses Passed Away for lifecycle, not care', (
    tester,
  ) async {
    const pet = Pet(
      id: 'buddy',
      name: 'Buddy',
      species: 'Dog',
      passedAway: true,
    );
    await tester.pumpWidget(
      buildCard(pet, careState: GuardianTodayPetCareState.overdue),
    );
    await tester.pump();

    expect(
      find.bySemanticsLabel('Buddy, My Pets, Passed Away'),
      findsOneWidget,
    );
  });

  // ── layout — no overflow at 320 logical px ──────────────────────────────────

  testWidgets('does not overflow at 320 logical px', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const pet = Pet(
      id: 'narrow',
      name: 'Sir Whiskers the Exceptionally Named Cat',
      species: 'Cat',
      isShared: true,
    );
    await tester.pumpWidget(buildCard(pet, cardWidth: 320));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  // ── tap callback is forwarded ────────────────────────────────────────────────

  testWidgets('invokes onTap when the card is tapped', (tester) async {
    var taps = 0;
    const pet = Pet(id: 'tap', name: 'Tap', species: 'Dog');
    await tester.pumpWidget(buildCard(pet, onTap: () => taps++));
    await tester.pump();

    tester.widget<InkWell>(find.byType(InkWell)).onTap!();
    expect(taps, 1);
  });

  // ── semantics node exposes an actual tap action ──────────────────────────────

  testWidgets('outer Semantics node exposes a tap action for screen readers', (
    tester,
  ) async {
    var taps = 0;
    const pet = Pet(id: 'semtap', name: 'SemTap', species: 'Cat');
    await tester.pumpWidget(buildCard(pet, onTap: () => taps++));
    await tester.pump();

    // Walk the semantics tree to find the node with the expected label.
    final semanticsOwner =
        tester.binding.renderViews.first.owner!.semanticsOwner!;
    SemanticsNode? targetNode;
    void walk(SemanticsNode node) {
      if (node.label == 'SemTap, My Pets, All clear') {
        targetNode = node;
        return;
      }
      node.visitChildren((child) {
        walk(child);
        return true;
      });
    }

    final root = semanticsOwner.rootSemanticsNode;
    expect(root, isNotNull, reason: 'Semantics tree must have a root');
    walk(root!);

    expect(targetNode, isNotNull, reason: 'Semantics node not found for label');
    // The node must advertise SemanticsAction.tap.
    expect(
      targetNode!.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
      reason: 'Semantics node must expose a tap action',
    );

    // Triggering the semantic action must invoke onTap.
    semanticsOwner.performAction(targetNode!.id, SemanticsAction.tap);
    await tester.pump();
    expect(taps, 1, reason: 'onTap must fire via the semantic tap action');
  });

  // ── photo placeholder shown when no photo path is set ───────────────────────

  testWidgets('renders a species icon placeholder when no photo is set', (
    tester,
  ) async {
    const pet = Pet(id: 'nophoto', name: 'Nophoto', species: 'Dog');
    await tester.pumpWidget(buildCard(pet));
    await tester.pump();

    // At minimum one Icon should be visible (species placeholder or chevron)
    expect(find.byType(Icon), findsAtLeastNWidgets(1));
    expect(find.byType(Image), findsNothing);
  });

  // ── passed-away photo overlay ────────────────────────────────────────────────

  testWidgets('applies a greyscale overlay for passed-away pets', (
    tester,
  ) async {
    const pet = Pet(id: 'gone', name: 'Gone', species: 'Dog', passedAway: true);
    await tester.pumpWidget(buildCard(pet));
    await tester.pump();

    expect(find.byType(ColorFiltered), findsOneWidget);
  });
}
