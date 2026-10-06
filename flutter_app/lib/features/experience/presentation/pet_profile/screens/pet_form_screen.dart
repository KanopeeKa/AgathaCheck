import 'package:flutter/material.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/core/utils/calendar_date_picker.dart';
import 'package:pet_profile_app/core/widgets/app_logo_title.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/core/widgets/form/app_form_discard_dialog.dart';
import 'package:pet_profile_app/features/people/people.dart';
import '../widgets/pet_form/pet_form_screen_body.dart';
import 'widgets/pet_form_edit_load_gate.dart';

part 'pet_form_screen_actions.part.dart';

class PetFormScreen extends ConsumerStatefulWidget {
  const PetFormScreen({super.key, this.petId, this.initialOrgId});

  final String? petId;
  final String? initialOrgId;

  @override
  ConsumerState<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends ConsumerState<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final PetFormController _controller;

  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _newWeightController = TextEditingController();
  final _bioController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _chipIdController = TextEditingController();

  DateTime? _neuteredDate;
  bool? _isNeutered;
  bool _passedAway = false;
  bool _isShared = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _showWeightInput = false;
  bool _suppressDirty = false;

  bool get _isEditing => widget.petId != null;

  @override
  void initState() {
    super.initState();
    _controller = PetFormController();
    if (!_isEditing && widget.initialOrgId != null) {
      _controller.setSelectedOrgId(widget.initialOrgId);
    }
    for (final controller in [
      _nameController,
      _breedController,
      _weightController,
      _newWeightController,
      _bioController,
      _insuranceController,
      _chipIdController,
    ]) {
      controller.addListener(_markDirty);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isEditing) _controller.captureBaseline();
    });
  }

  void _markDirty() {
    if (_suppressDirty) return;
    setState(() {});
  }

  void _onOwnershipChanged(String? orgId) {
    _controller.setSelectedOrgId(orgId);
    _markDirty();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _newWeightController.dispose();
    _bioController.dispose();
    _insuranceController.dispose();
    _chipIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (_isEditing && !_isInitialized) {
      return PetFormEditLoadGate(
        petId: widget.petId!,
        title: _formTitle(l),
        isInitialized: _isInitialized,
        onPetLoaded: (pet, {String? primaryVetContactId}) {
          setState(() {
            _populateForm(pet, primaryVetContactId: primaryVetContactId);
            _isInitialized = true;
          });
        },
        form: _buildForm(),
      );
    }

    return _buildForm();
  }

  Widget _buildForm() {
    final l = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final isPhone =
        PetFormBreakpoints.layoutForWidth(width) == PetFormLayoutSize.phone;

    return PopScope(
      canPop: !_controller.isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          _navigateAfterForm();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: AppLogoTitle(title: _formTitle(l)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l.goBack,
            onPressed: _handleBack,
          ),
        ),
        body: PetFormScreenBody(
          formKey: _formKey,
          controller: _controller,
          previewPet: _previewPet(),
          previewWeightLabel: _previewWeightLabel(),
          isEditing: _isEditing,
          petId: widget.petId,
          isLoading: _isLoading,
          isShared: _isShared,
          passedAway: _passedAway,
          showWeightInput: _showWeightInput,
          initialOrgId: widget.initialOrgId,
          nameController: _nameController,
          breedController: _breedController,
          weightController: _weightController,
          newWeightController: _newWeightController,
          bioController: _bioController,
          insuranceController: _insuranceController,
          chipIdController: _chipIdController,
          selectedPrimaryVetContactId:
              _controller.state.selectedPrimaryVetContactId,
          neuteredDate: _neuteredDate,
          isNeutered: _isNeutered,
          onChangePhoto: _pickImage,
          onOwnershipChanged: _onOwnershipChanged,
          onMarkDirty: _markDirty,
          onShowWeightInput: () {
            setState(() => _showWeightInput = true);
            _controller.setShowWeightInput(true);
            _markDirty();
          },
          onHideWeightInput: () {
            setState(() {
              _showWeightInput = false;
              _newWeightController.clear();
            });
            _controller.setShowWeightInput(false);
            _controller.setNewWeight('');
            _markDirty();
          },
          onNeuteredChanged: _onNeuteredChanged,
          onPickNeuteredDate: _pickNeuteredDate,
          onClearNeuteredDate: () {
            setState(() => _neuteredDate = null);
            _controller.state = _controller.state.copyWith(neuteredDate: null);
            _markDirty();
          },
          onPrimaryVetContactIdChanged: (value) {
            _controller.state = _controller.state.copyWith(
              selectedPrimaryVetContactId: value,
            );
            _markDirty();
          },
          onSave: _savePet,
          onCancel: _handleBack,
          onDelete: _confirmDeletePet,
          onPassedAway: _confirmPassedAway,
        ),
        bottomNavigationBar: isPhone
            ? PetFormStickyActionsBar(
                isEditing: _isEditing,
                isLoading: _isLoading,
                isDirty: _controller.isDirty,
                onSave: _savePet,
                onCancel: _handleBack,
              )
            : null,
      ),
    );
  }
}
