import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../config/app_constants.dart';
import '../../models/contact.dart';
import '../../models/contact_draft.dart';
import '../../providers/tag_provider.dart';
import '../../utils/form_input_validators.dart';
import '../../utils/unsaved_changes_guard.dart';
import '../../widgets/contact/contact_form_tags_section.dart';
import '../../widgets/common/side_sheet_scaffold.dart';
import 'contact_form_actions.dart';

class ContactFormScreen extends StatefulWidget {
  final Contact? initialContact;
  final String? initialName;
  final bool sideSheet;

  const ContactFormScreen({
    super.key,
    this.initialContact,
    this.initialName,
    this.sideSheet = false,
  });

  bool get isEditing => initialContact != null;

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  final Set<String> _selectedTagIds = <String>{};
  final Set<String> _initialTagIds = <String>{};
  bool _loadedInitialTags = false;
  bool _isSaving = false;
  bool _allowPop = false;
  bool _cachedHasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    final initialContact = widget.initialContact;
    _nameController = TextEditingController(text: initialContact?.name ?? widget.initialName ?? '');
    _phoneController = TextEditingController(text: initialContact?.phone ?? '');
    _emailController = TextEditingController(text: initialContact?.email ?? '');
    _addressController = TextEditingController(text: initialContact?.address ?? '');
    _notesController = TextEditingController(text: initialContact?.notes ?? '');
    _nameController.addListener(_onFormChanged);
    _phoneController.addListener(_onFormChanged);
    _emailController.addListener(_onFormChanged);
    _addressController.addListener(_onFormChanged);
    _notesController.addListener(_onFormChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTags();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? '编辑联系人' : '新建联系人';

    if (widget.sideSheet) {
      return PopScope(
        canPop: _allowPop || !_hasUnsavedChanges,
        child: SideSheetScaffold(
          title: title,
          onClose: _handleClose,
          action: FilledButton.tonal(
            onPressed: _isSaving ? null : _submit,
            child: const Text('保存'),
          ),
          body: _buildFormBody(),
        ),
      );
    }

    return PopScope(
      canPop: _allowPop || !_hasUnsavedChanges,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleClose,
          ),
          title: Text(title),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilledButton.tonal(
                onPressed: _isSaving ? null : _submit,
                child: const Text('保存'),
              ),
            ),
          ],
        ),
        body: _buildFormBody(),
      ),
    );
  }

  Future<void> _handleClose() async {
    final navigator = Navigator.of(context);
    if (_allowPop || !_hasUnsavedChanges) {
      navigator.pop();
      return;
    }
    final shouldDiscard = await showDiscardChangesDialog(context);
    if (shouldDiscard && context.mounted) {
      navigator.pop();
    }
  }

  Widget _buildFormBody() {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppDimensions.formMaxWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('contactForm_nameField'),
                    controller: _nameController,
                    maxLength: FormFieldLimits.contactName,
                    decoration: const InputDecoration(
                      labelText: '姓名',
                      hintText: '请输入联系人姓名',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) => FormInputValidators.requiredText(
                      value,
                      fieldName: '姓名',
                      maxLength: FormFieldLimits.contactName,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const Key('contactForm_phoneField'),
                    controller: _phoneController,
                    maxLength: FormFieldLimits.phone,
                    decoration: const InputDecoration(
                      labelText: '电话',
                      hintText: '请输入联系电话',
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: FormInputValidators.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const Key('contactForm_emailField'),
                    controller: _emailController,
                    maxLength: FormFieldLimits.email,
                    decoration: const InputDecoration(
                      labelText: '邮箱',
                      hintText: '请输入邮箱地址',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: FormInputValidators.email,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const Key('contactForm_addressField'),
                    controller: _addressController,
                    maxLength: FormFieldLimits.address,
                    decoration: const InputDecoration(
                      labelText: '地址',
                      hintText: '请输入地址',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) => FormInputValidators.optionalText(
                      value,
                      fieldName: '地址',
                      maxLength: FormFieldLimits.address,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const Key('contactForm_notesField'),
                    controller: _notesController,
                    maxLength: FormFieldLimits.notes,
                    decoration: const InputDecoration(
                      labelText: '备注',
                      hintText: '补充说明、关系背景或跟进信息',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    minLines: 3,
                    validator: (value) => FormInputValidators.optionalText(
                      value,
                      fieldName: '备注',
                      maxLength: FormFieldLimits.notes,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Consumer<TagProvider>(
                    builder: (context, tagProvider, child) {
                      return ContactFormTagsSection(
                        tags: tagProvider.tags,
                        selectedTagIds: _selectedTagIds,
                        loading: tagProvider.loading,
                        onManageTagsTap: _openTagManagement,
                        onTagToggle: _toggleTag,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    key: const Key('contactForm_submitButton'),
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.isEditing ? '保存修改' : '创建联系人'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _allowPop = true;
    });
    Navigator.of(context).pop(
      ContactDraft(
        name: _nameController.text.trim(),
        phone: _normalize(_phoneController.text),
        email: _normalize(_emailController.text),
        address: _normalize(_addressController.text),
        notes: _normalize(_notesController.text),
        tagIds: _selectedTagIds.toList(),
      ),
    );
  }

  Future<void> _initializeTags() async {
    final tagProvider = context.read<TagProvider>();
    if (!tagProvider.initialized) {
      await tagProvider.loadTags();
    }

    if (widget.isEditing && !_loadedInitialTags) {
      final tags = await tagProvider.getContactTags(widget.initialContact!.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _initialTagIds
          ..clear()
          ..addAll(tags.map((tag) => tag.id));
        _selectedTagIds
          ..clear()
          ..addAll(tags.map((tag) => tag.id));
        _loadedInitialTags = true;
      });
    }
  }

  Future<void> _openTagManagement() async {
    final validTagIds = await openTagManagementFromContactForm(context);
    if (!mounted || validTagIds == null) {
      return;
    }

    setState(() {
      _selectedTagIds.removeWhere((tagId) => !validTagIds.contains(tagId));
    });
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
    });
  }

  void _onFormChanged() {
    final current = _hasUnsavedChanges;
    if (current != _cachedHasUnsavedChanges) {
      setState(() {
        _cachedHasUnsavedChanges = current;
      });
    }
  }

  String? _normalize(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  bool get _hasUnsavedChanges {
    final initialContact = widget.initialContact;
    if (_normalize(_nameController.text) != (initialContact?.name ?? _normalize(widget.initialName ?? ''))) {
      return true;
    }
    if (_normalize(_phoneController.text) != initialContact?.phone) {
      return true;
    }
    if (_normalize(_emailController.text) != initialContact?.email) {
      return true;
    }
    if (_normalize(_addressController.text) != initialContact?.address) {
      return true;
    }
    if (_normalize(_notesController.text) != initialContact?.notes) {
      return true;
    }
    return !setEquals(_selectedTagIds, _initialTagIds);
  }
}