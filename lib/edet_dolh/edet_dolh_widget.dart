
import '/backend/admin_firestore_delete.dart';
import '/backend/admin_audit_log.dart';
import '/backend/admin_cascade_delete.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_super_admin_gate.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'edet_dolh_model.dart';
export 'edet_dolh_model.dart';

class EdetDolhWidget extends StatefulWidget {
  const EdetDolhWidget({
    super.key,
    required this.iddolhe,
  });

  final DocumentReference? iddolhe;

  static String routeName = 'EdetDolh';
  static String routePath = '/edetDolh';

  @override
  State<EdetDolhWidget> createState() => _EdetDolhWidgetState();
}

class _EdetDolhWidgetState extends State<EdetDolhWidget> {
  late EdetDolhModel _model;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EdetDolhModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _pickCountryImage() async {
    setState(() => _model.isDataUploading_uploadDataX8m = true);
    try {
      final url = await pickAndUploadAdminImage(
        context: context,
        storageFolder: 'countries/uploads',
        onLocalPreview: (bytes) {
          if (!mounted) return;
          setState(() {
            _model.uploadedLocalFile_uploadDataX8m =
                FFUploadedFile(bytes: bytes);
          });
        },
      );
      if (url == null) return;
      setState(() {
        _model.uploadedFileUrl_uploadDataX8m = url;
        _model.uploadedLocalFile_uploadDataX8m =
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
        setState(() => _model.isDataUploading_uploadDataX8m = false);
      }
    }
  }

  Future<void> _save(CountriesRecord record) async {
    final name = _model.textController1!.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم الدولة')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await AdminFirestoreDelete.updateDocument(
        widget.iddolhe!,
        createCountriesRecordData(
          naim: name,
          osf: _model.textController2!.text.trim(),
          img: await resolveImageForFirestoreSave(
            pickedUrl: _model.uploadedFileUrl_uploadDataX8m,
            existingUrl: record.img,
            localBytes: _model.uploadedLocalFile_uploadDataX8m.bytes,
          ),
          acctev: _model.switchValue ?? record.acctev,
          vatPercent:
              double.tryParse(_model.textController3!.text.trim()) ??
                  record.vatPercent,
          appCommissionPercent:
              double.tryParse(_model.textController4!.text.trim()) ??
                  record.appCommissionPercent,
        ),
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.edit,
        message: 'تم حفظ التعديلات بنجاح',
        refreshScope: AdminListScope.countries,
        popPage: true,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, 'تعذر الحفظ: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete(CountriesRecord record) async {
    if (!AdminSuperAdminGate.isAllowed) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text(
              'هل أنت متأكد من حذف "${record.naim}"؟\n'
              'سيتم حذف كل المناطق والمدن والمعالم المرتبطة.',
            ),
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
      await deleteCountryCascade(record.reference);
      await AdminAuditLog.recordDelete(
        targetType: 'country',
        targetId: record.reference.id,
        targetLabel: record.naim,
      );
      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.delete,
        message: 'تم حذف الدولة وكل البيانات المرتبطة',
        refreshScope: AdminListScope.countries,
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
    return StreamBuilder<CountriesRecord>(
      stream: CountriesRecord.getDocument(widget.iddolhe!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AdminEditScaffold(
            title: 'تعديل الدولة',
            isLoading: true,
            child: SizedBox.shrink(),
          );
        }

        final record = snapshot.data!;
        _model.bindCountriesRecord(record);

        return AdminEditScaffold(
          title: 'تعديل الدولة',
          subtitle: 'حدّث بيانات الدولة وصورتها وحالة التفعيل',
          child: AdminEditFormCard(
            children: [
              AdminEditableImageCard(
                imageUrl: _model.uploadedFileUrl_uploadDataX8m,
                localBytes: _model.uploadedLocalFile_uploadDataX8m.bytes,
                isUploading: _model.isDataUploading_uploadDataX8m,
                hint: 'اضغط لاختيار صورة العلم من المعرض أو الكاميرا',
                onPick: _pickCountryImage,
              ),
              const SizedBox(height: AdminUi.fieldGap),
              AdminTextField(
                controller: _model.textController1!,
                focusNode: _model.textFieldFocusNode1,
                label: 'اسم الدولة',
                icon: Icons.flag_rounded,
              ),
              const SizedBox(height: AdminUi.fieldGap),
              AdminTextField(
                controller: _model.textController2!,
                focusNode: _model.textFieldFocusNode2,
                label: 'وصف الدولة',
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: AdminUi.fieldGap),
              AdminTextField(
                controller: _model.textController3!,
                focusNode: _model.textFieldFocusNode3,
                label: 'نسبة الضريبة (%)',
                icon: Icons.percent_rounded,
                keyboardType: TextInputType.number,
                hint: 'مثال: 15',
              ),
              const SizedBox(height: AdminUi.fieldGap),
              AdminTextField(
                controller: _model.textController4!,
                focusNode: _model.textFieldFocusNode4,
                label: 'نسبة أرباح التطبيق (%)',
                icon: Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
                hint: 'مثال: 10',
              ),
              const SizedBox(height: AdminUi.fieldGap),
              AdminEditSwitchRow(
                label: 'تفعيل الدولة',
                subtitle: 'عند التفعيل تظهر الدولة في التطبيق',
                value: _model.switchValue ?? record.acctev,
                onChanged: (v) => setState(() => _model.switchValue = v),
              ),
            ],
          ),
          floatingAction: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (AdminSuperAdminGate.isAllowed) ...[
                OutlinedButton.icon(
                  onPressed: (_isSaving || _isDeleting)
                      ? null
                      : () => _delete(record),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red),
                  label: const Text(
                    'حذف الدولة',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 12),
              ],
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
