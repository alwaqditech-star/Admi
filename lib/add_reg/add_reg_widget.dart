import '/backend/backend.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_region_picker.dart';
import '/components/admin_ui.dart';
import '/backend/admin_agent_country_lock.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_reg_model.dart';
export 'add_reg_model.dart';

class AddRegWidget extends StatefulWidget {
  const AddRegWidget({super.key});

  static String routeName = 'AddReg';
  static String routePath = '/addReg';

  @override
  State<AddRegWidget> createState() => _AddRegWidgetState();
}

class _AddRegWidgetState extends State<AddRegWidget> {
  late AddRegModel _model;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddRegModel());

    _model.textFieldnaimTextController ??= TextEditingController();
    _model.textFieldnaimFocusNode ??= FocusNode();
    _model.textFieldDescTextController ??= TextEditingController();
    _model.textFieldDescFocusNode ??= FocusNode();
    _model.switchValue = true;

    AdminAgentCountryLock.applyToAppState();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _pickRegionImage() => handleAdminImagePick(
        context: context,
        storageFolder: 'regions/uploads',
        useContentCompression: true,
        setUploading: (v) =>
            safeSetState(() => _model.isDataUploading_uploadDataO6sc = v),
        setLocal: (file) =>
            safeSetState(() => _model.uploadedLocalFile_uploadDataO6sc = file),
        setUrl: (url) =>
            safeSetState(() => _model.uploadedFileUrl_uploadDataO6sc = url),
      );

  Future<void> _saveRegion() async {
    final name = _model.textFieldnaimTextController!.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم المنطقة')),
      );
      return;
    }
    if (FFAppState().RevDolh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الدولة')),
      );
      return;
    }

    if (_model.isDataUploading_uploadDataO6sc) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتظر اكتمال رفع الصورة ثم احفظ')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final img = await resolveImageForFirestoreSave(
        pickedUrl: _model.uploadedFileUrl_uploadDataO6sc,
        existingUrl: '',
        localBytes: _model.uploadedLocalFile_uploadDataO6sc.bytes,
      );

      await CitiesRecord.collection.doc().set(
            createCitiesRecordData(
              naim: name,
              osf: _model.textFieldDescTextController!.text.trim(),
              dolh: FFAppState().RevDolh,
              img: img,
              acctev: _model.switchValue,
            ),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة المنطقة بنجاح')),
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
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: AdminEditScaffold(
        title: 'إضافة منطقة جديدة',
        subtitle: 'اختر الدولة ثم أدخل بيانات المنطقة / المحافظة',
        isLoading: _isSaving,
        floatingAction: AdminPrimaryButton(
          label: 'حفظ المنطقة',
          icon: Icons.map_rounded,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _saveRegion,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminEditFormCard(
              sectionTitle: 'الدولة',
              children: [
                AdminEditPickerRow(
                  label: 'الدولة',
                  value: FFAppState().RevdolhTEXT,
                  placeholder: 'اختر الدولة',
                  onTap: () async {
                    await showAdminPickerSheet(
                      context: context,
                      child: const AdminCountryPickerSheet(),
                    );
                    if (mounted) safeSetState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: 'صورة المنطقة',
              children: [
                AdminEditableImageCard(
                  imageUrl: _model.uploadedFileUrl_uploadDataO6sc,
                  localBytes: _model.uploadedLocalFile_uploadDataO6sc.bytes,
                  isUploading: _model.isDataUploading_uploadDataO6sc,
                  hint: 'اضغط لاختيار صورة المنطقة',
                  onPick: _pickRegionImage,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: 'البيانات الأساسية',
              children: [
                TextFormField(
                  controller: _model.textFieldnaimTextController,
                  focusNode: _model.textFieldnaimFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'اسم المنطقة / المحافظة',
                    hintText: 'مثال: منطقة الرياض',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _model.textFieldDescTextController,
                  focusNode: _model.textFieldDescFocusNode,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'وصف المنطقة (اختياري)',
                    hintText: 'وصف مختصر',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                AdminEditSwitchRow(
                  label: 'تفعيل المنطقة',
                  subtitle: 'تظهر المنطقة في التطبيق عند التفعيل',
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
