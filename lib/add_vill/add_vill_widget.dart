import '/backend/backend.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_region_picker.dart';
import '/components/admin_ui.dart';
import '/backend/admin_agent_country_lock.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_vill_model.dart';
export 'add_vill_model.dart';

class AddVillWidget extends StatefulWidget {
  const AddVillWidget({super.key});

  static String routeName = 'addVill';
  static String routePath = '/addVill';

  @override
  State<AddVillWidget> createState() => _AddVillWidgetState();
}

class _AddVillWidgetState extends State<AddVillWidget> {
  late AddVillModel _model;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddVillModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();
    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();
    _model.switchValue = true;

    AdminAgentCountryLock.applyToAppState();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _pickCityImage() => handleAdminImagePick(
        context: context,
        storageFolder: 'cities/uploads',
        useContentCompression: true,
        setUploading: (v) =>
            safeSetState(() => _model.isDataUploading_uploadDataWt55 = v),
        setLocal: (file) =>
            safeSetState(() => _model.uploadedLocalFile_uploadDataWt55 = file),
        setUrl: (url) =>
            safeSetState(() => _model.uploadedFileUrl_uploadDataWt55 = url),
      );

  Future<void> _saveCity() async {
    if (FFAppState().RevDolh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الدولة')),
      );
      return;
    }
    if (FFAppState().Revreg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار المنطقة')),
      );
      return;
    }

    final name = _model.textController1!.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم المدينة')),
      );
      return;
    }

    if (_model.isDataUploading_uploadDataWt55) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتظر اكتمال رفع الصورة ثم احفظ')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final img = await resolveImageForFirestoreSave(
        pickedUrl: _model.uploadedFileUrl_uploadDataWt55,
        existingUrl: '',
        localBytes: _model.uploadedLocalFile_uploadDataWt55.bytes,
      );

      await VillagesRecord.collection.doc().set(
            createVillagesRecordData(
              cities: FFAppState().Revreg,
              dolh: FFAppState().RevDolh,
              naim: name,
              osf: _model.textController2!.text.trim(),
              acctev: _model.switchValue,
              img: img,
            ),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة المدينة بنجاح')),
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
        title: 'إضافة مدينة جديدة',
        subtitle: 'اختر الدولة والمنطقة ثم أدخل بيانات المدينة',
        isLoading: _isSaving,
        floatingAction: AdminPrimaryButton(
          label: 'حفظ المدينة',
          icon: Icons.location_city_rounded,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _saveCity,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminEditFormCard(
              sectionTitle: 'الموقع الجغرافي',
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
                const SizedBox(height: 14),
                AdminEditPickerRow(
                  label: 'المنطقة / المحافظة',
                  value: FFAppState().RevRegTEXT,
                  placeholder: 'اختر المنطقة',
                  onTap: () async {
                    if (FFAppState().RevDolh == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('يرجى اختيار الدولة أولاً'),
                        ),
                      );
                      return;
                    }
                    await showAdminPickerSheet(
                      context: context,
                      child: AdminRegionPickerSheet(
                        countryRef: FFAppState().RevDolh,
                      ),
                    );
                    if (mounted) safeSetState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: 'صورة المدينة',
              children: [
                AdminEditableImageCard(
                  imageUrl: _model.uploadedFileUrl_uploadDataWt55,
                  localBytes: _model.uploadedLocalFile_uploadDataWt55.bytes,
                  isUploading: _model.isDataUploading_uploadDataWt55,
                  hint: 'اضغط لاختيار صورة المدينة',
                  onPick: _pickCityImage,
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
                    labelText: 'اسم المدينة',
                    hintText: 'مثال: الرياض',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _model.textController2,
                  focusNode: _model.textFieldFocusNode2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'وصف المدينة (اختياري)',
                    hintText: 'وصف مختصر عن المدينة',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                AdminEditSwitchRow(
                  label: 'تفعيل المدينة',
                  subtitle: 'تظهر المدينة في التطبيق عند التفعيل',
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
