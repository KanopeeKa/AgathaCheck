import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/form/app_form_actions_bar.dart';
import '../../../../core/widgets/form/app_form_breakpoints.dart';
import '../../../../core/widgets/form/app_form_discard_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/people_api_exception.dart';
import '../../application/people_commands.dart';
import '../../application/people_providers.dart';
import '../../domain/entities/contact_detail.dart';
import '../../domain/entities/roster.dart';
import '../detail/person_detail_target.dart';
import 'person_edit_danger_zone.dart';
import 'person_form_controller.dart';
import 'person_form_errors.dart';
import 'sections/person_edit_contact_details_section.dart';
import 'sections/person_edit_identity_section.dart';
import 'sections/person_edit_notes_section.dart';
import 'sections/person_edit_pets_section.dart';
import 'sections/person_edit_works_at_section.dart';

class PersonEditContactForm extends ConsumerStatefulWidget {
  const PersonEditContactForm({
    super.key,
    required this.contactId,
    required this.roster,
  });

  final String contactId;
  final Roster roster;

  @override
  ConsumerState<PersonEditContactForm> createState() =>
      _PersonEditContactFormState();
}

class _PersonEditContactFormState extends ConsumerState<PersonEditContactForm> {
  final _formKey = GlobalKey<FormState>();
  PersonFormController? _controller;
  bool _saving = false;
  bool _dangerBusy = false;

  bool get _busy => _saving || _dangerBusy;

  Future<void> _handleBack() async {
    final controller = _controller;
    if (controller == null || !controller.isDirty) {
      if (mounted) context.pop();
      return;
    }
    if (await confirmDiscardFormChanges(context) && mounted) {
      context.pop();
    }
  }

  Future<void> _save() async {
    final controller = _controller;
    if (controller == null) return;
    if (!_formKey.currentState!.validate() || !controller.validate()) {
      setState(() {});
      return;
    }
    final patch = controller.buildPatch();
    if (patch.isEmpty) {
      if (mounted) context.pop(true);
      return;
    }
    setState(() => _saving = true);
    final l = AppLocalizations.of(context)!;
    try {
      await ref
          .read(peopleCommandsProvider)
          .patchContact(widget.contactId, patch);
      if (mounted) context.pop(true);
    } on PeopleApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(personFormSaveErrorMessage(l, e))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.peopleSaveError)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _actionsBar(AppLocalizations l, PersonFormController controller) {
    return AppFormActionsBar(
      isLoading: _busy,
      isDirty: controller.isDirty,
      onSave: _save,
      onCancel: _handleBack,
      saveLabel: l.save,
      cancelKey: const Key('people_edit_cancel'),
      saveKey: const Key('people_edit_save'),
    );
  }

  Widget _formBody(
    AppLocalizations l,
    ContactDetail detail,
    PersonFormController controller, {
    required bool includeActions,
  }) {
    final summary = widget.roster.summaryById(widget.contactId);
    final petLinks = summary?.pets ?? const [];
    final petOptions = rosterPetOptions(widget.roster);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PersonEditIdentitySection(controller: controller),
          const SizedBox(height: 16),
          PersonEditWorksAtSection(
            controller: controller,
            rosterContacts: widget.roster.contacts,
          ),
          const SizedBox(height: 16),
          PersonEditContactDetailsSection(controller: controller),
          const SizedBox(height: 16),
          PersonEditNotesSection(controller: controller),
          const SizedBox(height: 16),
          PersonEditPetsSection(
            contactId: widget.contactId,
            petLinks: petLinks,
            rosterPetOptions: petOptions,
          ),
          const SizedBox(height: 16),
          PersonEditDangerZone(
            controller: controller,
            onBusyChanged: (v) => setState(() => _dangerBusy = v),
          ),
          if (includeActions) ...[
            const SizedBox(height: 24),
            _actionsBar(l, controller),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(personDetailProvider(widget.contactId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: detailAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: Text(l.peopleEditPerson)),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => Scaffold(
          appBar: AppBar(title: Text(l.peopleEditPerson)),
          body: Center(child: Text(l.peopleListLoadError)),
        ),
        data: (detail) {
          if (detail == null) {
            return Scaffold(
              appBar: AppBar(title: Text(l.peopleEditPerson)),
              body: Center(child: Text(l.peopleDetailNotFound)),
            );
          }
          _controller ??= PersonFormController(initial: detail)
            ..addListener(() => setState(() {}));
          final controller = _controller!;
          final isPhone =
              AppFormBreakpoints.layoutForWidth(
                MediaQuery.sizeOf(context).width,
              ) ==
              AppFormLayoutSize.phone;
          final includeActions = !isPhone;

          return Scaffold(
            appBar: AppBar(
              title: Text(l.peopleEditPerson),
              leading: BackButton(onPressed: _handleBack),
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final form = _formBody(
                  l,
                  detail,
                  controller,
                  includeActions: includeActions,
                );
                if (isPhone) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    child: form,
                  );
                }
                return Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppFormBreakpoints.tabletContentMaxWidth,
                      ),
                      child: form,
                    ),
                  ),
                );
              },
            ),
            bottomNavigationBar: isPhone
                ? AppFormStickyActionsBar(
                    stickyKey: const Key('people_edit_sticky_actions'),
                    isLoading: _busy,
                    isDirty: controller.isDirty,
                    onSave: _save,
                    onCancel: _handleBack,
                    saveLabel: l.save,
                    cancelKey: const Key('people_edit_cancel'),
                    saveKey: const Key('people_edit_save'),
                  )
                : null,
          );
        },
      ),
    );
  }
}
