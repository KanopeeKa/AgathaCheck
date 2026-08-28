import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_adaptive_nav_title.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_shell_app_bar_title.dart';

void main() {
  testWidgets('dashboard variant centers logo and title as one block', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            leading: const SizedBox(width: 48, height: 48),
            actions: const [SizedBox(width: 48, height: 48)],
            title: const OrgShellAppBarTitle(
              title: 'Shelters dashboard',
              variant: OrgNavTitleVariant.dashboard,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final row = tester.getRect(find.byType(Row).last);
    final logo = tester.getRect(find.byType(Image));
    final text = tester.getRect(find.text('Shelters dashboard'));
    final blockCenter = (logo.left + text.right) / 2;

    expect(row.width, lessThan(300));
    expect((blockCenter - 195).abs(), lessThan(20));
    expect(logo.left, lessThan(text.left));
  });

  testWidgets('dashboard variant shows Agatha logo and adaptive title', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const OrgShellAppBarTitle(
              title: 'Shelters dashboard',
              variant: OrgNavTitleVariant.dashboard,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(OrgAdaptiveNavTitle), findsOneWidget);
    expect(find.text('Shelters dashboard'), findsOneWidget);
  });

  testWidgets('withOrgLogo variant shows org thumbnail and title', (
    tester,
  ) async {
    const org = Organization(
      id: 'org-1',
      name: 'Rescue Hearts',
      type: OrganizationType.charity,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const OrgShellAppBarTitle(
                title: 'Rescue Hearts',
                variant: OrgNavTitleVariant.withOrgLogo,
                organization: org,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.volunteer_activism), findsOneWidget);
    expect(find.text('Rescue Hearts'), findsOneWidget);
  });

  testWidgets('textOnly variant omits leading logos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const OrgShellAppBarTitle(
              title: 'Rescue Hearts',
              variant: OrgNavTitleVariant.textOnly,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.volunteer_activism), findsNothing);
    expect(find.byType(OrgAdaptiveNavTitle), findsOneWidget);
  });
}
