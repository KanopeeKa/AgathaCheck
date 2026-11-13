import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/app_logo_title.dart';
import '../../../../../core/widgets/form/app_form_labeled_field.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../application/support_form_providers.dart';
import '../../data/browser_family.dart';
import '../../data/fetch_site_version.dart';
import '../../data/site_version_info.dart';
import '../../data/support_ticket_submit_payload.dart';
import '../../data/support_tickets_api.dart';
import '../../domain/support_ticket_category.dart';
import '../widgets/support_form_bug_fields.dart';
import '../widgets/support_form_error_summary.dart';
import '../widgets/support_form_success_panel.dart';

class SupportIntakeFormScreen extends ConsumerStatefulWidget {
  const SupportIntakeFormScreen({
    super.key,
    this.signedIn = false,
    this.accessToken,
  });

  /// Whether the viewer is signed in (wired from [app_router.dart]).
  final bool signedIn;

  /// Optional bearer token when signed in.
  final String? accessToken;

  @override
  ConsumerState<SupportIntakeFormScreen> createState() =>
      _SupportIntakeFormScreenState();
}

class _SupportIntakeFormScreenState
    extends ConsumerState<SupportIntakeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _summaryFocusNode = FocusNode();
  final _titleFocusNode = FocusNode();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final _expectedController = TextEditingController();
  final _actualController = TextEditingController();
  final _stepsController = TextEditingController();

  SupportTicketCategory _category = SupportTicketCategory.bug;
  SupportBugFrequency? _frequency;
  SiteVersionInfo _siteVersion = SiteVersionInfo.empty();

  bool _submitting = false;
  int _validationErrorCount = 0;
  String? _serverError;
  String? _submittedReference;

  @override
  void initState() {
    super.initState();
    _loadSiteVersion();
  }

  Future<void> _loadSiteVersion() async {
    final info = await fetchSiteVersion();
    if (!mounted) return;
    setState(() => _siteVersion = info);
  }

  @override
  void dispose() {
    _summaryFocusNode.dispose();
    _titleFocusNode.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _expectedController.dispose();
    _actualController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  String _localeCode(BuildContext context) {
    return Localizations.localeOf(context).toLanguageTag();
  }

  Map<String, String> _buildContext() {
    return {
      'version': _siteVersion.version,
      'build': _siteVersion.build,
      'platform': 'web',
      'browser_family': detectBrowserFamily(),
      'locale': _localeCode(context),
      'route_name': 'contactSupport',
      'client_time': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<void> _submit() async {
    setState(() {
      _serverError = null;
      _validationErrorCount = 0;
    });

    final l = AppLocalizations.of(context)!;
    final signedIn = widget.signedIn;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      var errorCount = 0;
      if (_validateTitle(l) != null) errorCount++;
      if (_validateDescription(l) != null) errorCount++;
      if (!signedIn && _validateEmail(l) != null) errorCount++;

      setState(() => _validationErrorCount = errorCount);
      _summaryFocusNode.requestFocus();
      return;
    }

    setState(() => _submitting = true);

    final payload = SupportTicketSubmitPayload(
      category: _category,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      locale: _localeCode(context),
      context: _buildContext(),
      email: signedIn ? null : _emailController.text.trim(),
      expected: _trimOrNull(_expectedController.text),
      actual: _trimOrNull(_actualController.text),
      steps: _trimOrNull(_stepsController.text),
      frequency: _category == SupportTicketCategory.bug ? _frequency : null,
    );

    try {
      final baseApi = ref.read(supportTicketsApiProvider);
      final token = widget.accessToken;
      final api = token != null && token.isNotEmpty
          ? SupportTicketsApi(baseUrl: baseApi.baseUrl, accessToken: token)
          : baseApi;
      final reference = await api.submitTicket(payload);
      if (api != baseApi) {
        api.close();
      }
      if (!mounted) return;
      setState(() {
        _submittedReference = reference;
        _submitting = false;
      });
    } on SupportTicketSubmitException catch (e) {
      if (!mounted) return;
      final message = e.isUnauthorized
          ? l.supportFormErrorSessionExpired
          : e.isRateLimited
          ? l.supportFormErrorRateLimited
          : (e.fieldErrors.isNotEmpty ? e.fieldErrors.join('\n') : e.message);
      setState(() {
        _submitting = false;
        _serverError = message;
        _validationErrorCount = 0;
      });
      _summaryFocusNode.requestFocus();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _serverError = l.supportFormErrorGeneric;
      });
      _summaryFocusNode.requestFocus();
    }
  }

  String? _trimOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _validateTitle(AppLocalizations l) {
    final value = _titleController.text.trim();
    if (value.isEmpty) return l.supportFormValidationTitleRequired;
    if (value.length > 120) return l.supportFormValidationTitleTooLong;
    return null;
  }

  String? _validateDescription(AppLocalizations l) {
    final value = _descriptionController.text.trim();
    if (value.isEmpty) return l.supportFormValidationDescriptionRequired;
    if (value.length > 5000) return l.supportFormValidationDescriptionTooLong;
    return null;
  }

  String? _validateEmail(AppLocalizations l) {
    final value = _emailController.text.trim();
    if (value.isEmpty) return l.supportFormValidationEmailRequired;
    if (!value.contains('@')) return l.supportFormValidationEmailInvalid;
    if (value.length > 254) return l.supportFormValidationEmailTooLong;
    return null;
  }

  void _onCopyReference() {
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.peopleCopiedToClipboard)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final signedIn = widget.signedIn;
    final showSummary =
        _validationErrorCount > 0 ||
        (_serverError != null && _serverError!.isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: AppLogoTitle(title: l.contactHubHelpSupportTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _submittedReference != null
                ? SupportFormSuccessPanel(
                    reference: _submittedReference!,
                    onCopy: _onCopyReference,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.supportFormIntro,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      if (showSummary)
                        SupportFormErrorSummary(
                          key: const Key('support_form_error_summary'),
                          errorCount: _validationErrorCount,
                          focusNode: _summaryFocusNode,
                          serverMessage: _serverError,
                        ),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppFormLabeledField(
                              label: l.supportFormCategoryLabel,
                              isTextField: false,
                              child:
                                  DropdownButtonFormField<
                                    SupportTicketCategory
                                  >(
                                    key: const Key('support_form_category'),
                                    value: _category,
                                    decoration: const InputDecoration(),
                                    items: [
                                      DropdownMenuItem(
                                        value: SupportTicketCategory.bug,
                                        child: Text(l.supportFormCategoryBug),
                                      ),
                                      DropdownMenuItem(
                                        value: SupportTicketCategory.suggestion,
                                        child: Text(
                                          l.supportFormCategorySuggestion,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: SupportTicketCategory.account,
                                        child: Text(
                                          l.supportFormCategoryAccount,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: SupportTicketCategory.billing,
                                        child: Text(
                                          l.supportFormCategoryBilling,
                                        ),
                                      ),
                                    ],
                                    onChanged: _submitting
                                        ? null
                                        : (value) {
                                            if (value == null) return;
                                            setState(() => _category = value);
                                          },
                                  ),
                            ),
                            const SizedBox(height: 12),
                            AppFormLabeledField(
                              label: l.supportFormTitleLabel,
                              child: TextFormField(
                                key: const Key('support_form_title'),
                                controller: _titleController,
                                focusNode: _titleFocusNode,
                                maxLength: 120,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  counterText: '',
                                ),
                                validator: (_) => _validateTitle(l),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AppFormLabeledField(
                              label: l.supportFormDescriptionLabel,
                              child: TextFormField(
                                key: const Key('support_form_description'),
                                controller: _descriptionController,
                                minLines: 4,
                                maxLines: 8,
                                maxLength: 5000,
                                textInputAction: TextInputAction.newline,
                                decoration: const InputDecoration(
                                  counterText: '',
                                  alignLabelWithHint: true,
                                ),
                                validator: (_) => _validateDescription(l),
                              ),
                            ),
                            SupportFormBugFields(
                              visible: _category == SupportTicketCategory.bug,
                              expectedController: _expectedController,
                              actualController: _actualController,
                              stepsController: _stepsController,
                              frequency: _frequency,
                              onFrequencyChanged: (value) {
                                if (_submitting) return;
                                setState(() => _frequency = value);
                              },
                            ),
                            if (!signedIn) ...[
                              const SizedBox(height: 12),
                              AppFormLabeledField(
                                label: l.supportFormEmailLabel,
                                subtitle: l.supportFormEmailHint,
                                child: TextFormField(
                                  key: const Key('support_form_email'),
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(),
                                  validator: (_) => _validateEmail(l),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            FilledButton(
                              key: const Key('support_form_submit'),
                              onPressed: _submitting ? null : _submit,
                              child: _submitting
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(l.supportFormSubmitting),
                                      ],
                                    )
                                  : Text(l.supportFormSubmit),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
