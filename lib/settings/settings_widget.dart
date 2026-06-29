import 'dart:async';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_panel_setup.dart';
import '/backend/admin_country_backfill.dart';
import '/backend/admin_demo_seed.dart';
import '/backend/admin_production_landmark_seed.dart';
import '/backend/admin_role_service.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/profile_photo_service.dart';
import '/components/admin_image_picker.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_language_selector.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'settings_model.dart';
export 'settings_model.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  static String routeName = 'Settings';
  static String routePath = '/settings';

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  late SettingsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<UserRecord?>? _userProfileSub;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SettingsModel());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _model.loadProfileFromUser();
      safeSetState(() {});
    });

    _userProfileSub = authenticatedUserStream.listen((user) {
      if (!mounted || user == null) {
        return;
      }
      if (_model.isUploadingPhoto || _model.isSavingProfile) {
        return;
      }
      _model.applyUserProfile(user);
      safeSetState(() {});
    });
  }

  @override
  void dispose() {
    _userProfileSub?.cancel();
    _model.dispose();
    super.dispose();
  }

  Future<void> _seedDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة بيانات تجريبية'),
        content: const Text(
          'سيتم إنشاء 4 حسابات تجريبية (سوبر أدمن، وكيل، شريك، مدير نقل) '
          'مع دولة ومعالم وحجز تجريبي.\n\n'
          'كلمة المرور لجميع الحسابات: Demo@2026\n\n'
          'هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _model.isSeedingDemo = true);
    try {
      final result = await AdminDemoSeed.run();
      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإضافة: ${result.error}')),
        );
        return;
      }

      final lines = result.accounts
          .map((a) => '${a.roleLabel}: ${a.email}')
          .join('\n');

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تمت الإضافة بنجاح'),
          content: SingleChildScrollView(
            child: Text(
              'كلمة المرور: ${kDemoSeedPassword}\n\n$lines\n\n'
              'جديد: ${result.created} | موجود مسبقاً: ${result.skipped}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _model.isSeedingDemo = false);
    }
  }

  Future<void> _seedProductionData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعبئة بيانات الإنتاج'),
        content: const Text(
          'سيتم إضافة:\n'
          '• المملكة العربية السعودية + 12 منطقة ومدن\n'
          '• 50 معلم سياحي حقيقي مع صور وأوصاف\n'
          '• 96 حجزاً موزعة على سنة\n'
          '• تذاكر دعم وأنواع مركبات\n\n'
          'آمن للتشغيل أكثر من مرة (دمج البيانات).\n\n'
          'هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تعبئة البيانات'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _model.isSeedingProduction = true);
    try {
      final result = await AdminProductionLandmarkSeed.run();
      if (!mounted) return;

      if (!result.success) {
        final err = result.error ?? '';
        final friendly = err.contains('resource-exhausted') ||
                err.contains('Quota exceeded')
            ? 'تم تجاوز حصة كتابة Firebase اليومية. انتظر حتى إعادة التعيين (منتصف الليل بتوقيت Pacific) أو فعّل خطة Blaze، ثم أعد المحاولة.'
            : 'فشل التعبئة: $err';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendly)),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تمت التعبئة بنجاح'),
          content: Text(
            'معالم: ${result.landmarks}\n'
            'مناطق: ${result.regions}\n'
            'مدن: ${result.cities}\n'
            'حجوزات: ${result.orders}\n'
            'تذاكر دعم: ${result.supportTickets}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _model.isSeedingProduction = false);
    }
  }

  Future<void> _backfillCountryFields() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ربط البيانات بالدول'),
        content: const Text(
          'سيتم تعبئة حقل Rev_dolh للمعالم التي لها منطقة/مدينة معروفة، '
          'وللمناديب ومستخدمي التطبيق وتذاكر الدعم.\n\n'
          'المعالم القديمة بلا Rev_dolh تبقى لسوبر الأدمن فقط حتى يُربطها يدوياً.\n\n'
          'يُنفَّذ مرة واحدة بعد التحديث. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تنفيذ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _model.isCountryBackfilling = true);
    try {
      final result = await AdminCountryBackfill.run();
      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الربط: ${result.error}')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم الربط: ${result.landmarks} معلم، ${result.agents} وكيل، '
            '${result.representatives} مندوب، '
            '${result.appUsers} مستخدم، ${result.supportTickets} تذكرة دعم',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _model.isCountryBackfilling = false);
    }
  }

  Future<void> _backfillPartnerOrders() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('فهرسة حجوزات الشركاء'),
        content: const Text(
          'سيتم تعبئة حقل partner_mkans في الحجوزات النشطة '
          'لتسريع بوابة الشريك.\n\n'
          'يُنفَّذ مرة واحدة بعد التحديث. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تنفيذ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _model.isPartnerOrderBackfilling = true);
    try {
      final result = await AdminPanelSetup.runPartnerOrderBackfill();
      await AdminPanelSetup.resetPartnerMkansFlag();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم فحص ${result.scanned} حجز — '
            'تحديث ${result.updated}، تخطي ${result.skipped}',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الفهرسة: $e')),
      );
    } finally {
      if (mounted) setState(() => _model.isPartnerOrderBackfilling = false);
    }
  }

  Future<void> _persistPhotoUrl(String photoUrl) async {
    final userRef = currentUserReference;
    if (userRef == null) {
      throw Exception('لا يوجد مستخدم مسجل الدخول');
    }

    await userRef.set(
      createUserRecordData(photoUrl: photoUrl),
      SetOptions(merge: true),
    );

    currentUserDocument = await UserRecord.getDocumentOnce(userRef);

    if (!isProfilePhotoDataUrl(photoUrl)) {
      try {
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(photoUrl);
        await FirebaseAuth.instance.currentUser?.reload();
      } catch (_) {
        // Firestore يكفي للعرض داخل التطبيق.
      }
    }
  }

  Future<void> _pickProfilePhoto() async {
    if (currentUserUid.isEmpty || currentUserReference == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
      );
      return;
    }

    setState(() => _model.isUploadingPhoto = true);
    try {
      final downloadUrl = await pickAndUploadAdminImage(
        context: context,
        storageFolder: 'users/$currentUserUid/uploads',
        useUserProfileCompression: true,
        onLocalPreview: (bytes) {
          if (!mounted) return;
          setState(() {
            _model.uploadedLocalPhoto = FFUploadedFile(bytes: bytes);
          });
        },
      );
      if (downloadUrl == null) {
        return;
      }

      await _persistPhotoUrl(downloadUrl);

      setState(() {
        _model.uploadedPhotoUrl = downloadUrl;
        _model.photoUrlTextController!.text = downloadUrl;
        _model.uploadedLocalPhoto =
            FFUploadedFile(bytes: Uint8List.fromList([]));
      });

      if (!mounted) return;
      final usedFallback = isProfilePhotoDataUrl(downloadUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            usedFallback
                ? 'تم حفظ الصورة في حسابك (وضع احتياطي — فعّل فوترة Firebase Storage للرفع السحابي)'
                : 'تم تحديث الصورة الشخصية بنجاح',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر رفع الصورة: ${uploadErrorMessage(e)}')),
      );
    } finally {
      if (mounted) {
        setState(() => _model.isUploadingPhoto = false);
      }
    }
  }

  Widget _buildProfilePhotoSection(FlutterFlowTheme theme) {
    final photoUrl = _model.photoUrlTextController?.text ?? '';

    return AdminEditableImageCard(
      imageUrl: photoUrl,
      localBytes: _model.uploadedLocalPhoto.bytes,
      isUploading: _model.isUploadingPhoto,
      height: 160,
      hint: 'اضغط لاختيار صورة من المعرض أو الكاميرا (تُحفظ تلقائياً)',
      onPick: _pickProfilePhoto,
    );
  }

  Future<void> _saveProfile() async {
    if (!(_model.formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _model.isSavingProfile = true);
    try {
      final name = _model.nameTextController!.text.trim();
      final email = _model.emailTextController!.text.trim();
      final phone = _model.phoneTextController!.text.trim();
      final photoUrl = _model.photoUrlTextController!.text.trim();

      if (email != currentUserEmail) {
        await authManager.updateEmail(email: email, context: context);
      }

      await FirebaseAuth.instance.currentUser?.updateDisplayName(name);

      final userRef = currentUserReference;
      if (userRef == null) {
        throw Exception('لا يوجد مستخدم مسجل الدخول');
      }

      await userRef.set(
        createUserRecordData(
          displayName: name,
          phoneNumber: phone,
          photoUrl: photoUrl,
          email: email,
        ),
        SetOptions(merge: true),
      );

      currentUserDocument = await UserRecord.getDocumentOnce(userRef);

      if (photoUrl.isNotEmpty && !isProfilePhotoDataUrl(photoUrl)) {
        try {
          await FirebaseAuth.instance.currentUser?.updatePhotoURL(photoUrl);
          await FirebaseAuth.instance.currentUser?.reload();
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ بيانات الحساب بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ البيانات: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _model.isSavingProfile = false);
      }
    }
  }

  Future<void> _savePassword() async {
    if (!(_model.passwordFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _model.isSavingPassword = true);
    try {
      await authManager.updatePassword(
        newPassword: _model.newPasswordTextController!.text.trim(),
        context: context,
      );

      _model.newPasswordTextController?.clear();
      _model.confirmPasswordTextController?.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث كلمة المرور بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث كلمة المرور: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _model.isSavingPassword = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = FFLocalizations.of(context);
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: AdminLayoutWidget(
        scaffoldKey: scaffoldKey,
        menu2Model: _model.menu2Model,
        updateCallback: () => safeSetState(() {}),
        padContent: false,
        title: l10n.getText('003x6weg' /* Settings */),
        child: AdminPageBody(
          usePadding: false,
          title: l10n.getText('003x6weg' /* Settings */),
          subtitle: 'إدارة بيانات حسابك وتفضيلات التطبيق',
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminContentCard(
                    title: 'الملف الشخصي',
                    child: Form(
                      key: _model.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: _buildProfilePhotoSection(theme),
                          ),
                          const SizedBox(height: AdminUi.fieldGap),
                          AdminTextField(
                            controller: _model.nameTextController!,
                            focusNode: _model.nameFocusNode,
                            label: 'الاسم الكامل',
                            icon: Icons.badge_outlined,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'أدخل الاسم'
                                    : null,
                          ),
                          const SizedBox(height: AdminUi.fieldGap),
                          AdminTextField(
                            controller: _model.emailTextController!,
                            focusNode: _model.emailFocusNode,
                            label: l10n.getText('8gngx8fm' /* Email Address */),
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'أدخل البريد الإلكتروني';
                              }
                              if (!v.contains('@')) {
                                return 'بريد إلكتروني غير صالح';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AdminUi.fieldGap),
                          AdminTextField(
                            controller: _model.phoneTextController!,
                            focusNode: _model.phoneFocusNode,
                            label: 'رقم الهاتف',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          AdminPrimaryButton(
                            label: 'حفظ بيانات الحساب',
                            icon: Icons.save_outlined,
                            isLoading: _model.isSavingProfile,
                            onPressed: _saveProfile,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AdminContentCard(
                    title: l10n.getText('h9szauvt' /* Password */),
                    child: Form(
                      key: _model.passwordFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AdminTextField(
                            controller: _model.newPasswordTextController!,
                            focusNode: _model.newPasswordFocusNode,
                            label: 'كلمة المرور الجديدة',
                            icon: Icons.lock_outline,
                            obscureText: !_model.passwordVisible,
                            visibilityVisible: _model.passwordVisible,
                            onToggleVisibility: () => setState(
                              () => _model.passwordVisible =
                                  !_model.passwordVisible,
                            ),
                            validator: (v) {
                              if (v == null || v.length < 6) {
                                return '6 أحرف على الأقل';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AdminUi.fieldGap),
                          AdminTextField(
                            controller:
                                _model.confirmPasswordTextController!,
                            focusNode: _model.confirmPasswordFocusNode,
                            label: 'تأكيد كلمة المرور',
                            icon: Icons.lock_outline,
                            obscureText: !_model.confirmPasswordVisible,
                            visibilityVisible: _model.confirmPasswordVisible,
                            onToggleVisibility: () => setState(
                              () => _model.confirmPasswordVisible =
                                  !_model.confirmPasswordVisible,
                            ),
                            validator: (v) {
                              if (v !=
                                  _model.newPasswordTextController!.text) {
                                return 'كلمتا المرور غير متطابقتين';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AdminPrimaryButton(
                            label: 'تحديث كلمة المرور',
                            icon: Icons.vpn_key_outlined,
                            isLoading: _model.isSavingPassword,
                            onPressed: _savePassword,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (AdminRoleService.isSuperAdmin)
                    AdminContentCard(
                      title: 'بيانات النظام',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'تعبئة معالم سياحية حقيقية، حجوزات على مدى سنة، ومناطق سعودية — '
                            'لجعل النظام جاهزاً للعرض والتشغيل. '
                            'إذا ظهرت رسالة تجاوز الحصة، انتظر إعادة تعيين Firebase أو فعّل Blaze.',
                            style: theme.bodySmall.override(
                              fontFamily: theme.bodySmallFamily,
                              color: theme.secondaryText,
                              useGoogleFonts: !theme.bodySmallIsCustom,
                            ),
                          ),
                          const SizedBox(height: 12),
                          AdminPrimaryButton(
                            label: 'تعبئة بيانات الإنتاج (معالم + حجوزات)',
                            icon: Icons.landscape_rounded,
                            isLoading: _model.isSeedingProduction,
                            onPressed: _model.isSeedingProduction
                                ? null
                                : _seedProductionData,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'بيانات تجريبية للاختبار (4 مستخدمين + حسابات Demo@2026).',
                            style: theme.bodySmall.override(
                              fontFamily: theme.bodySmallFamily,
                              color: theme.secondaryText,
                              useGoogleFonts: !theme.bodySmallIsCustom,
                            ),
                          ),
                          const SizedBox(height: 12),
                          AdminPrimaryButton(
                            label: 'إضافة البيانات التجريبية',
                            icon: Icons.science_outlined,
                            isLoading: _model.isSeedingDemo,
                            onPressed:
                                _model.isSeedingDemo ? null : _seedDemoData,
                          ),
                          const SizedBox(height: 12),
                          AdminPrimaryButton(
                            label: 'ربط البيانات بالدول',
                            icon: Icons.public_rounded,
                            isLoading: _model.isCountryBackfilling,
                            onPressed: _model.isCountryBackfilling
                                ? null
                                : _backfillCountryFields,
                          ),
                          const SizedBox(height: 12),
                          AdminPrimaryButton(
                            label: 'فهرسة حجوزات الشركاء',
                            icon: Icons.receipt_long_outlined,
                            isLoading: _model.isPartnerOrderBackfilling,
                            onPressed: _model.isPartnerOrderBackfilling
                                ? null
                                : _backfillPartnerOrders,
                          ),
                        ],
                      ),
                    ),
                  if (AdminRoleService.isSuperAdmin)
                    const SizedBox(height: 16),
                  AdminContentCard(
                    title: 'الخصوصية وشروط الاستخدام',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'باستخدامك لوحة التحكم، فإنك توافق على معالجة بيانات '
                          'المستخدمين والحجوزات والمواقع الجغرافية لأغراض تشغيل '
                          'الخدمة فقط. لا تُشارك البيانات مع أطراف ثالثة إلا بموافقة '
                          'قانونية أو بموجب القانون.',
                          style: theme.bodySmall.override(
                            fontFamily: theme.bodySmallFamily,
                            color: theme.secondaryText,
                            useGoogleFonts: !theme.bodySmallIsCustom,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'يحق للمستخدمين طلب تصحيح أو حذف بياناتهم عبر الدعم الفني. '
                          'يُحظر استخدام النظام لأغراض غير مشروعة أو انتهاك خصوصية '
                          'العملاء أو المناديب.',
                          style: theme.bodySmall.override(
                            fontFamily: theme.bodySmallFamily,
                            color: theme.secondaryText,
                            useGoogleFonts: !theme.bodySmallIsCustom,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'آخر تحديث: يونيو 2026',
                          style: theme.labelSmall.override(
                            fontFamily: theme.labelSmallFamily,
                            color: theme.secondaryText,
                            useGoogleFonts: !theme.labelSmallIsCustom,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AdminContentCard(
                    child: Align(
                      alignment: Alignment.center,
                      child: FlutterFlowLanguageSelector(
                        width: double.infinity,
                        backgroundColor: theme.primary,
                        borderColor: Colors.transparent,
                        dropdownIconColor: Colors.white,
                        borderRadius: AdminUi.radiusSm,
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14.0,
                        ),
                        hideFlags: true,
                        flagSize: 24.0,
                        flagTextGap: 8.0,
                        currentLanguage: l10n.languageCode,
                        languages: FFLocalizations.languages(),
                        onChanged: (lang) => setAppLanguage(context, lang),
                      ),
                    ),
                  ),
                  AdminContentCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout_rounded, color: theme.error),
                      title: Text(
                        l10n.getText('wj2hxjyt' /* Log out */),
                        style: theme.bodyMedium.override(
                          fontFamily: theme.bodyMediumFamily,
                          color: theme.error,
                          fontWeight: FontWeight.w600,
                          useGoogleFonts: !theme.bodyMediumIsCustom,
                        ),
                      ),
                      onTap: () async {
                        GoRouter.of(context).prepareAuthEvent();
                        await authManager.signOut();
                        GoRouter.of(context).clearRedirectLocation();
                        if (!context.mounted) return;
                        context.goNamedAuth(
                          HomePageWidget.routeName,
                          context.mounted,
                        );
                      },
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
