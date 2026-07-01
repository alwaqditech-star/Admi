import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Creates Firebase Auth users without signing out the current admin session.
class AdminUserCreation {
  AdminUserCreation._();

  static const _secondaryAppName = 'AdminUserCreation';

  /// Arabic message for common Firebase Auth failures.
  static String authErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'البريد الإلكتروني مستخدم مسبقاً. استخدم بريداً آخر أو عدّل الوكيل الحالي.';
        case 'weak-password':
          return 'كلمة المرور ضعيفة. يجب أن تكون 6 أحرف على الأقل.';
        case 'invalid-email':
          return 'البريد الإلكتروني غير صالح.';
        case 'operation-not-allowed':
          return 'إنشاء الحسابات غير مفعّل في Firebase Auth.';
        case 'network-request-failed':
          return 'تحقق من الاتصال بالإنترنت وحاول مرة أخرى.';
        default:
          return 'تعذر إنشاء الحساب: ${error.message ?? error.code}';
      }
    }
    return error.toString();
  }

  static Future<UserCredential> createEmailUser({
    required String email,
    required String password,
  }) async {
    final secondary = await _secondaryApp();
    final auth = FirebaseAuth.instanceFor(app: secondary);
    try {
      return await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(authErrorMessage(e));
    } finally {
      await auth.signOut();
    }
  }

  static Future<FirebaseApp> _secondaryApp() async {
    try {
      return Firebase.app(_secondaryAppName);
    } catch (_) {
      return Firebase.initializeApp(
        name: _secondaryAppName,
        options: Firebase.app().options,
      );
    }
  }
}
