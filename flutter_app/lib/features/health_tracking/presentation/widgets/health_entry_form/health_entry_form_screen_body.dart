import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/form/app_form_breakpoints.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../controllers/health_entry_form_controller.dart';
import '../../controllers/health_entry_form_state.dart';
import 'health_entry_document_handler.dart';
import 'health_entry_form_content.dart';
import 'health_entry_form_preview_card.dart';

/// Responsive body for the add/edit health entry form screen.
class HealthEntryFormScreenBody extends ConsumerWidget {
  const HealthEntryFormScreenBody({
    super.key,
    required this.formKey,
    required this.params,
    required this.documents,
    required this.baseUrl,
    required this.actionsBar,
    this.onDelete,
  });

  final GlobalKey<FormState> formKey;
  final HealthEntryFormParams params;
  final HealthEntryDocumentHandler documents;
  final String baseUrl;
  final Widget actionsBar;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(healthEntryFormControllerProvider(params));
    final petsAsync = ref.watch(petListProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = AppFormBreakpoints.layoutForWidth(constraints.maxWidth);
        final petNames = petsAsync.maybeWhen(
          data: (pets) => pets
              .where((p) => form.selectedPetIds.contains(p.id))
              .map((p) => p.name)
              .toList(),
          orElse: () => <String>[],
        );

        final content = HealthEntryFormContent(
          formKey: formKey,
          params: params,
          documents: documents,
          baseUrl: baseUrl,
          includeActionsBar: layout != AppFormLayoutSize.phone,
          actionsBar: actionsBar,
          onDelete: onDelete,
        );

        return switch (layout) {
          AppFormLayoutSize.phone => SingleChildScrollView(
            key: const Key('health_entry_form_layout_phone'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            child: content,
          ),
          AppFormLayoutSize.tablet => Align(
            key: const Key('health_entry_form_layout_tablet'),
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppFormBreakpoints.tabletContentMaxWidth,
                ),
                child: content,
              ),
            ),
          ),
          AppFormLayoutSize.desktop => Align(
            key: const Key('health_entry_form_layout_desktop'),
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppFormBreakpoints.desktopPageMaxWidth,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: HealthEntryFormPreviewCard(
                        name: form.name,
                        type: form.type,
                        dosage: form.dosage,
                        dueDate: form.dueDate,
                        completedOn: form.completedOn,
                        petNames: petNames,
                      ),
                    ),
                    const SizedBox(width: 32),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppFormBreakpoints.desktopFormMaxWidth,
                      ),
                      child: content,
                    ),
                  ],
                ),
              ),
            ),
          ),
        };
      },
    );
  }
}
