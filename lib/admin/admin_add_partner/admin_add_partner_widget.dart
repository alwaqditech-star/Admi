import '/backend/admin_agent_country_lock.dart';
import '/backend/admin_role_service.dart';
import '/components/admin_crud_feedback.dart';
import '/backend/admin_user_creation.dart';
import '/backend/backend.dart';
import '/components/admin_edit_shell.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_location_section.dart';
import '/components/admin_location_service.dart';
import '/components/admin_region_picker.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_add_partner_model.dart';
export 'admin_add_partner_model.dart';

class AdminAddPartnerWidget extends StatefulWidget {
  const AdminAddPartnerWidget({super.key});

  static String routeName = 'AdminAddPartner';
  static String routePath = '/adminAddPartner';

  @override
  State<AdminAddPartnerWidget> createState() => _AdminAddPartnerWidgetState();
}

class _AdminAddPartnerWidgetState extends State<AdminAddPartnerWidget> {
  late AdminAddPartnerModel _model;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminAddPartnerModel());

    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();
    _model.descriptionTextController ??= TextEditingController();
    _model.descriptionFocusNode ??= FocusNode();
    _model.phoneTextController ??= TextEditingController();
    _model.phoneFocusNode ??= FocusNode();
    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();
    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();
    _model.confirmPasswordTextController ??= TextEditingController();
    _model.confirmPasswordFocusNode ??= FocusNode();

    AdminAgentCountryLock.applyToAppState();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _pickMainImage() => handleAdminImagePick(
        context: context,
        storageFolder: 'landmarks/uploads',
        useContentCompression: true,
        setUploading: (v) =>
            safeSetState(() => _model.isDataUploading_mainImage = v),
        setLocal: (file) =>
            safeSetState(() => _model.uploadedLocalFile_mainImage = file),
        setUrl: (url) =>
            safeSetState(() => _model.uploadedFileUrl_mainImage = url),
      );

  Future<void> _pickSecondImage() => handleAdminImagePick(
        context: context,
        storageFolder: 'landmarks/uploads',
        useContentCompression: true,
        setUploading: (v) =>
            safeSetState(() => _model.isDataUploading_secondImage = v),
        setLocal: (file) =>
            safeSetState(() => _model.uploadedLocalFile_secondImage = file),
        setUrl: (url) =>
            safeSetState(() => _model.uploadedFileUrl_secondImage = url),
      );

  Future<void> _savePartner() async {
    final name = _model.nameTextController!.text.trim();
    final description = _model.descriptionTextController!.text.trim();
    final phone = _model.phoneTextController!.text.trim();
    final email = _model.emailTextController!.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم الشريك')),
      );
      return;
    }
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال وصف الخدمات')),
      );
      return;
    }
    if (FFAppState().REvCITE == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار المدينة')),
      );
      return;
    }

    final password = _model.passwordTextController!.text;
    final confirmPassword = _model.confirmPasswordTextController!.text;
    if (email.isNotEmpty) {
      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كلمة مرور الحساب يجب أن تكون 6 أحرف على الأقل')),
        );
        return;
      }
      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كلمتا مرور الحساب غير متطابقتين')),
        );
        return;
      }
    }

    final location = AdminLocationService.isValidLocation(
          _model.placePickerValue.latLng,
        )
        ? _model.placePickerValue.latLng
        : _model.googleMapsCenter;
    if (location == null ||
        !AdminLocationService.isValidLocation(location)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد موقع الشريك على الخريطة')),
      );
      return;
    }

    if (_model.isDataUploading_mainImage ||
        _model.isDataUploading_secondImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتظر اكتمال رفع الصور ثم احفظ')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final img1 = await resolveImageForFirestoreSave(
        pickedUrl: _model.uploadedFileUrl_mainImage,
        existingUrl: '',
        localBytes: _model.uploadedLocalFile_mainImage.bytes,
      );
      final img2 = await resolveImageForFirestoreSave(
        pickedUrl: _model.uploadedFileUrl_secondImage,
        existingUrl: '',
        localBytes: _model.uploadedLocalFile_secondImage.bytes,
      );

      if (img1.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إضافة صورة للشريك')),
        );
        return;
      }

      final address = _model.placePickerValue.address.isNotEmpty
          ? _model.placePickerValue.address
          : AdminLocationService.formatCoordinates(location);

      final mkanRef = MkanRecord.collection.doc();

      await mkanRef.set({
        ...createMkanRecordData(
          naim: name,
          osf: description,
          img1: img1,
          img2: img2,
          idVill: FFAppState().REvCITE,
          idCit: FFAppState().Revreg,
          revDolh: FFAppState().RevDolh,
          location: location,
          address: address,
          acctev: _model.activeValue,
          asAds: true,
          ismzod: true,
          isShrek: true,
          rate: _model.ratingValue,
          mdh: phone,
          tsnef: 'شريك سياحي',
        ),
        if (email.isNotEmpty) 'EmailUser': email,
        'dataAdd': FieldValue.serverTimestamp(),
      });

      if (email.isNotEmpty) {
        final credential = await AdminUserCreation.createEmailUser(
          email: email,
          password: password,
        );
        final uid = credential.user?.uid;
        if (uid == null) {
          throw Exception('تعذر إنشاء حساب الشريك');
        }

        await UserRecord.collection.doc(uid).set(
              createUserRecordData(
                displayName: name,
                email: email,
                phoneNumber: phone,
                actevUser: true,
                createdTime: getCurrentTimestamp,
                isPartner: true,
                partnerMkanRef: mkanRef,
                isAdminRule: AdminRoleService.rulePartner,
              ),
              SetOptions(merge: true),
            );

        await mkanRef.update(
          createMkanRecordData(
            userMalk: UserRecord.collection.doc(uid),
          ),
        );
      }

      if (!mounted) return;
      await AdminCrudFeedback.success(
        context,
        action: AdminCrudAction.add,
        message: email.isNotEmpty
            ? 'تم إضافة الشريك وحسابه بنجاح'
            : 'تم إضافة الشريك بنجاح',
        refreshScopes: [
          AdminListScope.partners,
          AdminListScope.landmarks,
        ],
        popPage: true,
      );
    } catch (e) {
      if (!mounted) return;
      AdminCrudFeedback.error(context, 'تعذر الحفظ: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildStarRating() {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final filled = _model.ratingValue >= starValue;
        return InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () {
            safeSetState(() {
              if (_model.ratingValue == starValue.toDouble()) {
                _model.ratingValue = (starValue - 1).toDouble();
              } else {
                _model.ratingValue = starValue.toDouble();
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              filled ? Icons.star : Icons.star_border,
              color: const Color(0xFFFFD700),
              size: 32,
            ),
          ),
        );
      }),
    );
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
        title: 'إضافة شريك جديد',
        subtitle: 'أدخل بيانات الشريك السياحي لإضافته إلى قائمة الشركاء',
        isLoading: _isSaving,
        floatingAction: AdminPrimaryButton(
          label: 'حفظ الشريك',
          icon: Icons.handshake_rounded,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _savePartner,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminEditFormCard(
              sectionTitle: 'البيانات الأساسية',
              children: [
                TextFormField(
                  controller: _model.nameTextController,
                  focusNode: _model.nameFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'اسم الشريك / الشركة',
                    hintText: 'مثال: شركة الرحلات الذهبية',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _model.descriptionTextController,
                  focusNode: _model.descriptionFocusNode,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'وصف الخدمات',
                    hintText: 'اكتب وصفاً مختصراً لخدمات الشريك',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _model.phoneTextController,
                  focusNode: _model.phoneFocusNode,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الجوال',
                    hintText: '05xxxxxxxx',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _model.emailTextController,
                  focusNode: _model.emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني لحساب الشريك',
                    hintText: 'partner@example.com',
                    helperText: 'يُنشأ حساب دخول للشريك عند إدخال البريد وكلمة المرور',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _model.passwordTextController,
                  focusNode: _model.passwordFocusNode,
                  obscureText: !_model.passwordVisibility,
                  decoration: InputDecoration(
                    labelText: 'كلمة مرور الحساب',
                    hintText: '6 أحرف على الأقل',
                    suffixIcon: InkWell(
                      onTap: () => safeSetState(
                        () => _model.passwordVisibility =
                            !_model.passwordVisibility,
                      ),
                      child: Icon(
                        _model.passwordVisibility
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _model.confirmPasswordTextController,
                  focusNode: _model.confirmPasswordFocusNode,
                  obscureText: !_model.confirmPasswordVisibility,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    suffixIcon: InkWell(
                      onTap: () => safeSetState(
                        () => _model.confirmPasswordVisibility =
                            !_model.confirmPasswordVisibility,
                      ),
                      child: Icon(
                        _model.confirmPasswordVisibility
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: 'الصور',
              children: [
                AdminEditableImageCard(
                  imageUrl: _model.uploadedFileUrl_mainImage,
                  localBytes: _model.uploadedLocalFile_mainImage.bytes,
                  isUploading: _model.isDataUploading_mainImage,
                  hint: 'الصورة الرئيسية للشريك',
                  onPick: _pickMainImage,
                ),
                const SizedBox(height: 12),
                AdminEditableImageCard(
                  imageUrl: _model.uploadedFileUrl_secondImage,
                  localBytes: _model.uploadedLocalFile_secondImage.bytes,
                  isUploading: _model.isDataUploading_secondImage,
                  hint: 'صورة إضافية (اختياري)',
                  height: 160,
                  onPick: _pickSecondImage,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: 'الموقع',
              children: [
                AdminLocationSection(
                  place: _model.placePickerValue,
                  mapController: _model.googleMapsController,
                  initialCenter: _model.googleMapsCenter,
                  onPlaceChanged: (place) {
                    safeSetState(() {
                      _model.placePickerValue = place;
                      _model.googleMapsCenter = place.latLng;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                        const SnackBar(content: Text('يرجى اختيار الدولة أولاً')),
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
                const SizedBox(height: 14),
                AdminEditPickerRow(
                  label: 'المدينة',
                  value: FFAppState().RevciteTEXT,
                  placeholder: 'اختر المدينة',
                  onTap: () async {
                    await showAdminPickerSheet(
                      context: context,
                      child: AdminCityPickerSheet(
                        regionRef: FFAppState().Revreg,
                      ),
                    );
                    if (mounted) safeSetState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            AdminEditFormCard(
              sectionTitle: 'إعدادات إضافية',
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'التقييم',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    _buildStarRating(),
                  ],
                ),
                const SizedBox(height: 14),
                AdminEditSwitchRow(
                  label: 'تفعيل الشريك',
                  subtitle: 'يظهر الشريك في التطبيق عند التفعيل',
                  value: _model.activeValue,
                  onChanged: (v) => safeSetState(() => _model.activeValue = v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
