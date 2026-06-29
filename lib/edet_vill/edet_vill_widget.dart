
import '/backend/admin_firestore_delete.dart';
import '/backend/admin_audit_log.dart';
import '/backend/admin_cascade_delete.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_region_picker.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'edet_vill_model.dart';
export 'edet_vill_model.dart';

class EdetVillWidget extends StatefulWidget {
  const EdetVillWidget({
    super.key,
    required this.idvill,
  });

  final DocumentReference? idvill;

  static String routeName = 'edetVill';
  static String routePath = '/edetVill';

  @override
  State<EdetVillWidget> createState() => _EdetVillWidgetState();
}

class _EdetVillWidgetState extends State<EdetVillWidget> {
  late EdetVillModel _model;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EdetVillModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadLocationLabels(VillagesRecord record) async {
    if (_model.labelsLoaded) return;

    if (record.cities != null) {
      FFAppState().Revreg = record.cities;
      try {
        final region = await CitiesRecord.getDocumentOnce(record.cities!);
        if (!mounted) return;
        _model.regionLabel = region.naim;
        FFAppState().RevRegTEXT = region.naim;
        if (region.dolh != null) {
          FFAppState().RevDolh = region.dolh;
          final country = await CountriesRecord.getDocumentOnce(region.dolh!);
          if (!mounted) return;
          _model.countryLabel = country.naim;
          FFAppState().RevdolhTEXT = country.naim;
        }
      } catch (_) {}
    } else if (record.dolh != null) {
      FFAppState().RevDolh = record.dolh;
      try {
        final country = await CountriesRecord.getDocumentOnce(record.dolh!);
        if (!mounted) return;
        _model.countryLabel = country.naim;
        FFAppState().RevdolhTEXT = country.naim;
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _model.labelsLoaded = true);
    }
  }

  Future<void> _pickCityImage() async {
    setState(() => _model.isDataUploading_uploadDataWt5 = true);
    try {
      final url = await pickAndUploadAdminImage(
        context: context,
        storageFolder: 'cities/uploads',
        onLocalPreview: (bytes) {
          if (!mounted) return;
          setState(() {
            _model.uploadedLocalFile_uploadDataWt5 =
                FFUploadedFile(bytes: bytes);
          });
        },
      );
      if (url == null) return;
      setState(() {
        _model.uploadedFileUrl_uploadDataWt5 = url;
        _model.uploadedLocalFile_uploadDataWt5 =
            FFUploadedFile(bytes: Uint8List.fromList([]));
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم اختيار الصورة بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر رفع الصورة: ${uploadErrorMessage(e)}')),
      );
    } finally {
      if (mounted) {
        setState(() => _model.isDataUploading_uploadDataWt5 = false);
      }
    }
  }

  Future<void> _save(VillagesRecord record) async {
    final name = _model.textController1!.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم المدينة')),
      );
      return;
    }
    if (FFAppState().Revreg == null && record.cities == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار المنطقة')),
      );
      return;
    }
    if (FFAppState().RevDolh == null && record.dolh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الدولة')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await AdminFirestoreDelete.updateDocument(
        record.reference,
        createVillagesRecordData(
          cities: FFAppState().Revreg ?? record.cities,
          dolh: FFAppState().RevDolh ?? record.dolh,
          naim: name,
          osf: _model.textController2!.text.trim(),
          img: await resolveImageForFirestoreSave(
            pickedUrl: _model.uploadedFileUrl_uploadDataWt5,
            existingUrl: record.img,
            localBytes: _model.uploadedLocalFile_uploadDataWt5.bytes,
          ),
          acctev: _model.switchValue ?? record.acctev,
        ),
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: 'تم حفظ التعديلات بنجاح',
        refreshScope: AdminListScope.cities,
        popPage: true,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, 'تعذر الحفظ: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete(VillagesRecord record) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('هل أنت متأكد من حذف "${record.naim}"؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('لا'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('نعم، احذف'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _isDeleting = true);
    try {
      await deleteCityCascade(record.reference);
      await AdminAuditLog.recordDelete(
        targetType: 'city',
        targetId: record.reference.id,
        targetLabel: record.naim,
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.delete,
        message: 'تم حذف المدينة والمعالم المرتبطة',
        refreshScope: AdminListScope.cities,
        removedDocumentId: record.reference.id,
        deletedRef: record.reference,
        popPage: true,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, 'تعذر الحذف: $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return StreamBuilder<VillagesRecord>(
      stream: VillagesRecord.getDocument(widget.idvill!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AdminEditScaffold(
            title: 'تعديل المدينة',
            isLoading: true,
            child: SizedBox.shrink(),
          );
        }

        final record = snapshot.data!;
        _model.bindVillagesRecord(record);
        // ignore: unawaited_futures
        _loadLocationLabels(record);

        final countryLabel = FFAppState().RevdolhTEXT.isNotEmpty
            ? FFAppState().RevdolhTEXT
            : (_model.countryLabel ?? '');
        final regionLabel = FFAppState().RevRegTEXT.isNotEmpty
            ? FFAppState().RevRegTEXT
            : (_model.regionLabel ?? '');

        return AdminEditScaffold(
          title: 'تعديل المدينة',
          subtitle: 'حدّث بيانات المدينة وموقعها وصورتها',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminEditFormCard(
                children: [
                  AdminEditableImageCard(
                    imageUrl: _model.uploadedFileUrl_uploadDataWt5,
                    localBytes: _model.uploadedLocalFile_uploadDataWt5.bytes,
                    isUploading: _model.isDataUploading_uploadDataWt5,
                    hint: 'اختر صورة المدينة من المعرض أو الكاميرا',
                    onPick: _pickCityImage,
                  ),
                ],
              ),
              const SizedBox(height: AdminUi.sectionGap),
              AdminEditFormCard(
                sectionTitle: 'الموقع',
                children: [
                  AdminEditPickerRow(
                    label: 'الدولة',
                    value: countryLabel,
                    placeholder: 'اختر الدولة',
                    onTap: () async {
                      final previousCountry = FFAppState().RevDolh;
                      await showAdminPickerSheet(
                        context: context,
                        child: const AdminCountryPickerSheet(),
                      );
                      if (!mounted) return;
                      if (previousCountry != FFAppState().RevDolh) {
                        clearRegionAndCitySelection();
                        _model.regionLabel = '';
                      }
                      setState(() {
                        _model.countryLabel = FFAppState().RevdolhTEXT;
                      });
                    },
                  ),
                  const SizedBox(height: AdminUi.fieldGap),
                  AdminEditPickerRow(
                    label: 'المنطقة',
                    value: regionLabel,
                    placeholder: countryLabel.isEmpty
                        ? 'اختر الدولة أولاً'
                        : 'اختر المنطقة',
                    onTap: () async {
                      if (countryLabel.isEmpty &&
                          FFAppState().RevDolh == null) {
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
                      if (mounted) {
                        setState(() {
                          _model.regionLabel = FFAppState().RevRegTEXT;
                          _model.countryLabel =
                              FFAppState().RevdolhTEXT.isNotEmpty
                                  ? FFAppState().RevdolhTEXT
                                  : _model.countryLabel;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: AdminUi.sectionGap),
              AdminEditFormCard(
                sectionTitle: 'البيانات',
                children: [
                  AdminTextField(
                    controller: _model.textController1!,
                    focusNode: _model.textFieldFocusNode1,
                    label: 'اسم المدينة',
                    icon: Icons.location_city_rounded,
                  ),
                  const SizedBox(height: AdminUi.fieldGap),
                  AdminTextField(
                    controller: _model.textController2!,
                    focusNode: _model.textFieldFocusNode2,
                    label: 'وصف المدينة',
                    icon: Icons.notes_rounded,
                  ),
                  const SizedBox(height: AdminUi.fieldGap),
                  AdminEditSwitchRow(
                    label: 'تفعيل المدينة',
                    subtitle: 'تظهر المدينة في التطبيق عند التفعيل',
                    value: _model.switchValue ?? record.acctev,
                    onChanged: (v) => setState(() => _model.switchValue = v),
                  ),
                ],
              ),
            ],
          ),
          floatingAction: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: (_isSaving || _isDeleting)
                    ? null
                    : () => _delete(record),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red),
                label: const Text(
                  'حذف المدينة',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 12),
              AdminPrimaryButton(
                label: 'حفظ التعديلات',
                icon: Icons.save_rounded,
                isLoading: _isSaving,
                onPressed: () => _save(record),
              ),
            ],
          ),
        );
      },
    );
  }
}
