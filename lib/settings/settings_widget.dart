import 'dart:async';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/firebase_storage/storage.dart';
import '/backend/profile_photo_service.dart';
import '/components/admin_crud_feedback.dart';
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
        SnackBar(content: Text(uiTr(context, 'يجب تسجيل الدخول أولاً'))),
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
        SnackBar(content: Text(AdminCrudFeedback.uploadFailed(context, uploadErrorMessage(e)))),
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
        SnackBar(content: Text(uiTr(context, 'تم حفظ بيانات الحساب بنجاح'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appTr(context, 'adm_save_data_failed')}: $e')),
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
        SnackBar(content: Text(uiTr(context, 'تم تحديث كلمة المرور بنجاح'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appTr(context, 'adm_password_update_failed')}: $e')),
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
          subtitle: uiTr(context, 'إدارة بيانات حسابك وتفضيلات التطبيق'),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminContentCard(
                    title: uiTr(context, 'الملف الشخصي'),
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
                            label: uiTr(context, 'الاسم الكامل'),
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
                            label: uiTr(context, 'رقم الهاتف'),
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          AdminPrimaryButton(
                            label: uiTr(context, 'حفظ بيانات الحساب'),
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
                            label: uiTr(context, 'كلمة المرور الجديدة'),
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
                            label: uiTr(context, 'تأكيد كلمة المرور'),
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
                            label: uiTr(context, 'تحديث كلمة المرور'),
                            icon: Icons.vpn_key_outlined,
                            isLoading: _model.isSavingPassword,
                            onPressed: _savePassword,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AdminContentCard(
                    title: uiTr(context, 'الخصوصية وشروط الاستخدام'),
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
