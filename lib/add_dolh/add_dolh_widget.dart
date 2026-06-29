import '/backend/backend.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_super_admin_gate.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'add_dolh_model.dart';
export 'add_dolh_model.dart';

class AddDolhWidget extends StatefulWidget {
  const AddDolhWidget({super.key});

  static String routeName = 'AddDolh';
  static String routePath = '/addDolh';

  @override
  State<AddDolhWidget> createState() => _AddDolhWidgetState();
}

class _AddDolhWidgetState extends State<AddDolhWidget> {
  late AddDolhModel _model;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddDolhModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();
    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();
    _model.textController3 ??= TextEditingController(text: '0');
    _model.textFieldFocusNode3 ??= FocusNode();
    _model.textController4 ??= TextEditingController(text: '0');
    _model.textFieldFocusNode4 ??= FocusNode();
    _model.switchValue = true;

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _pickCountryImage() => handleAdminImagePick(
        context: context,
        storageFolder: 'countries/uploads',
        useContentCompression: true,
        setUploading: (v) =>
            safeSetState(() => _model.isDataUploading_uploadDataX8mc = v),
        setLocal: (file) =>
            safeSetState(() => _model.uploadedLocalFile_uploadDataX8mc = file),
        setUrl: (url) =>
            safeSetState(() => _model.uploadedFileUrl_uploadDataX8mc = url),
      );

  Future<void> _saveCountry() async {
    final name = _model.textController1!.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم الدولة')),
      );
      return;
    }

    if (_model.isDataUploading_uploadDataX8mc) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتظر اكتمال رفع الصورة ثم احفظ')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final img = await resolveImageForFirestoreSave(
        pickedUrl: _model.uploadedFileUrl_uploadDataX8mc,
        existingUrl: '',
        localBytes: _model.uploadedLocalFile_uploadDataX8mc.bytes,
      );

      await CountriesRecord.collection.doc().set(
            createCountriesRecordData(
              naim: name,
              osf: _model.textController2!.text.trim(),
              acctev: _model.switchValue,
              img: img,
              vatPercent:
                  double.tryParse(_model.textController3!.text.trim()) ?? 0,
              appCommissionPercent:
                  double.tryParse(_model.textController4!.text.trim()) ?? 0,
            ),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة الدولة بنجاح')),
      );
      context.safePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الحفظ: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AdminSuperAdminGate.isProfileLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('إضافة دولة')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!AdminSuperAdminGate.isAllowed) {
      return AdminSuperAdminGate.deniedEditScaffold(
        context: context,
        title: 'إضافة دولة',
      );
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: AdminEditScaffold(
        title: 'إضافة دولة جديدة',
        subtitle: 'أدخل بيانات الدولة لإضافتها إلى النظام',
        isLoading: _isSaving,
        floatingAction: AdminPrimaryButton(
          label: 'حفظ الدولة',
          icon: Icons.public_rounded,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _saveCountry,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminEditFormCard(
              sectionTitle: 'صورة الدولة',
              children: [
                AdminEditableImageCard(
                  imageUrl: _model.uploadedFileUrl_uploadDataX8mc,
                  localBytes: _model.uploadedLocalFile_uploadDataX8mc.bytes,
                  isUploading: _model.isDataUploading_uploadDataX8mc,
                  hint: 'اضغط لاختيار صورة الدولة',
                  onPick: _pickCountryImage,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: 'البيانات الأساسية',
              children: [
                TextFormField(
                  controller: _model.textController1,
                  focusNode: _model.textFieldFocusNode1,
                  decoration: const InputDecoration(
                    labelText: 'اسم الدولة',
                    hintText: 'مثال: المملكة العربية السعودية',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _model.textController2,
                  focusNode: _model.textFieldFocusNode2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'وصف الدولة (اختياري)',
                    hintText: 'وصف مختصر عن الدولة',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _model.textController3,
                  focusNode: _model.textFieldFocusNode3,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'نسبة الضريبة (%)',
                    hintText: 'مثال: 15',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _model.textController4,
                  focusNode: _model.textFieldFocusNode4,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'نسبة أرباح التطبيق (%)',
                    hintText: 'مثال: 10',
                  ),
                ),
                const SizedBox(height: 14),
                AdminEditSwitchRow(
                  label: 'تفعيل الدولة',
                  subtitle: 'تظهر الدولة في التطبيق عند التفعيل',
                  value: _model.switchValue ?? true,
                  onChanged: (v) => safeSetState(() => _model.switchValue = v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
