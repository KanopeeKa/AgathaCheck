import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/shell_return_navigation.dart';
import '../../../../core/utils/calendar_date_picker.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pet.dart';
import '../controllers/pet_form_controller.dart';
import '../controllers/pet_form_error_messages.dart';
import '../controllers/pet_form_outcomes.dart';
import '../providers/pet_providers.dart';
import '../widgets/pet_form/pet_form_confirm_dialogs.dart';
import 'widgets/pet_form_screen_body.dart';

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

  String? _selectedVetId;
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

  void _navigateAfterForm() {
    if (widget.initialOrgId != null) {
      context.go('/organizations/${widget.initialOrgId}');
      return;
    }
    if (_isEditing && widget.petId != null) {
      goToPetDetail(context, widget.petId!);
      return;
    }
    if (_controller.state.selectedOrgId != null) {
      context.go('/organizations/${_controller.state.selectedOrgId}');
      return;
    }
    context.go('/');
  }

  Future<bool> _confirmDiscard() async {
    if (!_controller.isDirty || !mounted) return true;
    final l = AppLocalizations.of(context)!;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.petFormUnsavedTitle),
        content: Text(l.petFormUnsavedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.petFormDiscard),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _handleBack() async {
    if (!_controller.isDirty) {
      _navigateAfterForm();
      return;
    }
    if (await _confirmDiscard() && mounted) {
      _navigateAfterForm();
    }
  }

  String _formTitle(AppLocalizations l) {
    if (!_isEditing) return l.addPetTitle;
    final name = _nameController.text.trim();
    if (name.isNotEmpty) return l.editPetNamed(name);
    return l.editPetTitle;
  }

  Pet _previewPet() {
    final species = _controller.state.selectedSpecies;
    return Pet(
      id: widget.petId ?? 'new',
      name: _nameController.text.trim().isEmpty
          ? ' '
          : _nameController.text.trim(),
      species: species.isEmpty ? 'Dog' : species,
      photoPath: _controller.state.photoBase64,
      colorValue: _controller.state.existingColorValue,
      passedAway: _passedAway,
    );
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

  void _populateForm(Pet pet) {
    _suppressDirty = true;
    _nameController.text = pet.name;
    _breedController.text = pet.breed;
    _weightController.text = pet.weight?.toString() ?? '';
    _bioController.text = pet.bio;
    _insuranceController.text = pet.insurance;
    _chipIdController.text = pet.chipId;
    _selectedVetId = pet.vetId;
    _neuteredDate = pet.neuteredDate;
    _isNeutered = pet.neuteredDate != null
        ? true
        : pet.neuterDismissed
        ? false
        : null;
    _passedAway = pet.passedAway;
    _isShared = pet.isShared;

    _controller.populateForm(pet);
    _controller.captureBaseline();
    _suppressDirty = false;
  }

  Future<void> _pickImage() async {
    final outcome = await _controller.pickImage();
    if (!mounted) return;

    _markDirty();
    final l = AppLocalizations.of(context)!;
    switch (outcome) {
      case PetFormPickImageSuccess():
        break;
      case PetFormPickImageFailed(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(petFormPickImageErrorMessage(l, error))),
        );
    }
  }

  Future<void> _pickNeuteredDate() async {
    final now = DateTime.now();
    final picked = await showCalendarDatePicker(
      context: context,
      initialDate: _neuteredDate ?? now,
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _neuteredDate = picked);
      _controller.state = _controller.state.copyWith(
        neuteredDate: picked,
        neuterDismissed: false,
      );
      _markDirty();
    }
  }

  void _onNeuteredChanged(bool? val) {
    setState(() {
      _isNeutered = val;
      if (val != true) _neuteredDate = null;
    });
    if (val == true) {
      _controller.state = _controller.state.copyWith(
        isNeutered: true,
        neuterDismissed: false,
      );
    } else if (val == false) {
      _controller.state = _controller.state.copyWith(
        isNeutered: false,
        neuteredDate: null,
      );
    } else {
      _controller.state = _controller.state.copyWith(
        isNeutered: null,
        neuteredDate: null,
      );
    }
    _markDirty();
  }

  Future<void> _confirmDeletePet() async {
    if (widget.petId == null) return;
    await confirmDeletePet(
      context: context,
      ref: ref,
      petId: widget.petId!,
      petName: _nameController.text.trim(),
      onLoadingChanged: (bool loading) {
        if (mounted) setState(() => _isLoading = loading);
      },
    );
  }

  Future<void> _confirmPassedAway() async {
    if (widget.petId == null) return;
    await confirmPassedAway(
      context: context,
      ref: ref,
      petId: widget.petId!,
      onLoadingChanged: (bool loading) {
        if (mounted) setState(() => _isLoading = loading);
      },
    );
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final outcome = await _controller.submit(
        PetFormSubmitDeps.fromWidgetRef(ref),
        isEditing: _isEditing,
        petId: widget.petId,
      );
      if (!mounted) return;

      final l = AppLocalizations.of(context)!;
      switch (outcome) {
        case PetFormSubmitValidationFailed(:final reason):
          final message = switch (reason) {
            PetFormSubmitValidation.nameRequired => l.petNameRequired,
            PetFormSubmitValidation.invalidWeight => l.petInvalidWeight,
            PetFormSubmitValidation.petNotFound => l.petNotFound,
          };
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        case PetFormSubmitError(:final kind):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(petFormSubmitErrorMessage(l, kind))),
          );
        case PetFormSubmitSuccess():
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.petFormPetSaved)),
          );
          _navigateAfterForm();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (_isEditing && !_isInitialized) {
      final petAsync = ref.watch(petByIdProvider(widget.petId!));
      return petAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: AppLogoTitle(title: _formTitle(l))),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: AppLogoTitle(title: _formTitle(l))),
          body: Center(child: Text(l.petNotFound)),
        ),
        data: (pet) {
          if (pet != null && !_isInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _populateForm(pet);
                _isInitialized = true;
              });
            });
          }
          return _buildForm();
        },
      );
    }

    return _buildForm();
  }

  Widget _buildForm() {
    final l = AppLocalizations.of(context)!;

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
          isEditing: _isEditing,
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
          selectedVetId: _selectedVetId,
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
          onVetSelected: (value) {
            setState(() => _selectedVetId = value);
            _markDirty();
          },
          onSave: _savePet,
          onCancel: _handleBack,
          onDelete: _confirmDeletePet,
          onPassedAway: _confirmPassedAway,
        ),
      ),
    );
  }
}
