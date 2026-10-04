import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/controllers/health_entry_form_controller.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_form/health_entry_booster_dates_field.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _Harness extends ConsumerStatefulWidget {
  const _Harness({required this.params});

  final HealthEntryFormParams params;

  @override
  ConsumerState<_Harness> createState() => _HarnessState();
}

class _HarnessState extends ConsumerState<_Harness> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(
        healthEntryFormControllerProvider(widget.params).notifier,
      );
      notifier.setCareFamily(CareFamily.vaccination);
      notifier.setDueDate(DateTime(2026, 6, 1));
      notifier.addBoosterDate(DateTime(2026, 7, 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(healthEntryFormControllerProvider(widget.params));
    return HealthEntryBoosterDatesField(params: widget.params, form: form);
  }
}

void main() {
  testWidgets('UIR-15 shows removable booster date chip', (tester) async {
    const params = HealthEntryFormParams();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: const _Harness(params: params)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('health_entry_booster_2026-07-01')), findsOneWidget);
    expect(find.text('+ Add a booster date'), findsOneWidget);
  });
}
