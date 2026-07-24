import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '/core/cloud_functions/cloud_functions_client.dart';

/// Creates panel users via Cloud Functions (server-side only).
class AdminUserCreation {
  AdminUserCreation._();

  static String authErrorMessage(Object error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'already-exists':
          return 'البريد الإلكتروني مستخدم مسبقاً. استخدم بريداً آخر أو عدّل الوكيل الحالي.';
        case 'invalid-argument':
          return 'البريد الإلكتروني أو كلمة المرور غير صالحة.';
        case 'permission-denied':
          return 'ليس لديك صلاحية إنشاء هذا النوع من الحسابات.';
        case 'unauthenticated':
          return 'يجب تسجيل الدخول أولاً.';
        default:
          return 'تعذر إنشاء الحساب: ${error.message ?? error.code}';
      }
    }
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'البريد الإلكتروني مستخدم مسبقاً.';
        case 'weak-password':
          return 'كلمة المرور ضعيفة. يجب أن تكون 6 أحرف على الأقل.';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صالح.';
        default:
          return 'تعذر إنشاء الحساب: ${error.message ?? error.code}';
      }
    }
    return error.toString();
  }

  static Future<String> createEmailUser({
    required String email,
    required String password,
    Map<String, dynamic> userData = const {},
  }) async {
    try {
      final result = await CloudFunctionsClient.createPanelUser(
        email: email,
        password: password,
        userData: userData,
      );
      final uid = result['uid'] as String?;
      if (uid == null || uid.isEmpty) {
        throw Exception('تعذر إنشاء الحساب.');
      }
      return uid;
    } catch (e) {
      throw Exception(authErrorMessage(e));
    }
  }
}
