import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Creates Firebase Auth users without signing out the current admin session.
class AdminUserCreation {
  AdminUserCreation._();

  static const _secondaryAppName = 'AdminUserCreation';

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
