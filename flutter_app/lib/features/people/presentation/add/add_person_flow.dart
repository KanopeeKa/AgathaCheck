import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/form/app_form_breakpoints.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../sharing/sharing.dart';
import '../../application/people_api_exception.dart';
import '../../application/people_commands.dart';
import '../../application/people_providers.dart';
import '../../domain/entities/contact_detail.dart';
import '../edit/person_form_errors.dart';
import 'add_person_app_access.dart';
import 'add_person_flow_controller.dart';
import 'add_person_route_args.dart';
import 'add_person_step_finalize.dart';
import 'add_person_steps.dart';

class AddPersonFlow extends ConsumerStatefulWidget {
  const AddPersonFlow({super.key, this.args});

  final AddPersonRouteArgs? args;

  @override
  ConsumerState<AddPersonFlow> createState() => _AddPersonFlowState();
}

class _AddPersonFlowState extends ConsumerState<AddPersonFlow> {
  late final AddPersonFlowController _controller;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = AddPersonFlowController(
      initialEntry: widget.args?.initialEntry,
    );
    if (widget.args?.initialEntry != null) {
      _controller.selectEntry(widget.args!.initialEntry!);
      _controller.advanceStep();
    }
    _controller.addListener(_onFlowChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onFlowChanged);
    super.dispose();
  }

  void _onFlowChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final entry = _controller.entry;
    if (entry == null) return;
    if (!_controller.form.validate()) {
      setState(() {});
      return;
    }
    setState(() => _saving = true);
    final l = AppLocalizations.of(context)!;
    try {
      String? householdId;
      if (_controller.appAccess == AddPersonAppAccessChoice.householdInvite) {
        householdId = await _resolveHouseholdId();
      }
      final body = _controller.buildCreateBody(householdId: householdId);
      final detail = await ref
          .read(peopleRepositoryProvider)
          .createContact(body);
      await ref
          .read(peopleCommandsProvider)
          .afterContactMutation(
            detail.id,
            petIds: _controller.pets
                .where((p) => p.selected)
                .map((p) => p.petId)
                .toList(),
          );
      if (!mounted) return;
      await _afterSave(detail);
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

  Future<String?> _resolveHouseholdId() async {
    final households = await ref
        .read(householdsRepositoryProvider)
        .listHouseholds();
    if (households.isNotEmpty) return households.first.id;
    final name = _controller.householdName;
    if (name == null || name.isEmpty) return null;
    final created = await ref
        .read(householdsRepositoryProvider)
        .createHousehold(name);
    return created.id;
  }

  Future<void> _afterSave(ContactDetail detail) async {
    final args = widget.args;
    final access = _controller.appAccess;
    final email = _controller.form.email.trim();

    if (access == AddPersonAppAccessChoice.sharePets && email.isNotEmpty) {
      final petIds = _controller.pets
          .where((p) => p.selected)
          .map((p) => p.petId)
          .toList();
      if (petIds.isNotEmpty && mounted) {
        context.push(
          '/pc/pets/share',
          extra: SharePetRouteArgs(
            petIds: petIds,
            contactId: detail.id,
            prefillEmail: email,
          ),
        );
        return;
      }
    }

    if (access == AddPersonAppAccessChoice.householdInvite &&
        email.isNotEmpty) {
      final householdId = await _resolveHouseholdId();
      if (householdId != null) {
        await ref
            .read(householdsRepositoryProvider)
            .createHouseholdInvite(
              householdId: householdId,
              inviteeEmail: email,
              contactId: detail.id,
            );
      }
    }

    if (args?.popResultOnSave == true) {
      context.pop(detail.toSummary());
      return;
    }
    if (mounted) {
      context.go('/pc/people/${detail.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final layout = AppFormBreakpoints.layoutForWidth(width);
    final isDialog = layout != AppFormLayoutSize.phone;

    final content = _AddPersonFlowBody(
      controller: _controller,
      saving: _saving,
      onBack: _handleBack,
      onNext: _handleNext,
      onSave: _save,
    );

    if (isDialog) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppFormBreakpoints.desktopFormMaxWidth,
            maxHeight: 720,
          ),
          child: content,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.peopleAddPerson),
        leading: BackButton(onPressed: _handleBack),
      ),
      body: content,
    );
  }

  void _handleBack() {
    if (_controller.stepIndex > 0) {
      _controller.backStep();
      return;
    }
    context.pop();
  }

  void _handleNext() {
    final onLast =
        _controller.stepIndex >= AddPersonFlowController.stepCount - 1;
    if (onLast) {
      _save();
      return;
    }
    _controller.advanceStep();
  }
}

class _AddPersonFlowBody extends StatelessWidget {
  const _AddPersonFlowBody({
    required this.controller,
    required this.saving,
    required this.onBack,
    required this.onNext,
    required this.onSave,
  });

  final AddPersonFlowController controller;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final step = controller.stepIndex + 1;
    final entry = controller.entry;
    final isLast =
        controller.stepIndex >= AddPersonFlowController.stepCount - 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l.peopleAddStepProgress(step),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _stepBody(context),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (controller.stepIndex > 0)
                  TextButton(onPressed: onBack, child: Text(l.peopleAddBack)),
                const Spacer(),
                FilledButton(
                  onPressed:
                      saving || entry == null && controller.stepIndex == 0
                      ? null
                      : onNext,
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isLast ? l.peopleAddPersonSave : l.peopleAddNext),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepBody(BuildContext context) {
    switch (controller.stepIndex) {
      case 0:
        return AddPersonStepWho(controller: controller);
      case 1:
        return AddPersonStepAbout(controller: controller);
      case 2:
        return AddPersonStepRoles(controller: controller);
      case 3:
        return AddPersonStepPets(controller: controller);
      case 4:
        final entry = controller.entry;
        if (entry != null && entry.showsAppAccessStep) {
          return AddPersonStepAppAccess(controller: controller);
        }
        return AddPersonStepReview(controller: controller);
      default:
        return const SizedBox.shrink();
    }
  }
}
