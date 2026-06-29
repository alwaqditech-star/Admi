import 'package:cloud_firestore/cloud_firestore.dart';

/// Ensures admin Firestore writes persist on the server (not UI-only).
abstract final class AdminFirestoreDelete {
  AdminFirestoreDelete._();

  static const _verifyAttempts = 4;
  static const _verifyDelay = Duration(milliseconds: 500);
  static const _pendingWritesTimeout = Duration(seconds: 20);

  static Future<void> _ensureOnline() async {
    try {
      await FirebaseFirestore.instance.enableNetwork();
    } catch (_) {}
  }

  static Future<void> _awaitServerCommit() async {
    try {
      await FirebaseFirestore.instance
          .waitForPendingWrites()
          .timeout(_pendingWritesTimeout);
    } catch (_) {}
  }

  /// Confirms [ref] no longer exists on the server.
  static Future<void> verifyDeleted(DocumentReference ref) async {
    await _ensureOnline();
    for (var attempt = 0; attempt < _verifyAttempts; attempt++) {
      final snap = await ref.get(const GetOptions(source: Source.server));
      if (!snap.exists) return;
      if (attempt < _verifyAttempts - 1) {
        await Future<void>.delayed(_verifyDelay);
      }
    }
    throw StateError('تعذر حذف السجل من قاعدة البيانات');
  }

  /// Confirms [ref] exists on the server after create/update.
  static Future<void> verifySaved(DocumentReference ref) async {
    await _ensureOnline();
    for (var attempt = 0; attempt < _verifyAttempts; attempt++) {
      final snap = await ref.get(const GetOptions(source: Source.server));
      if (snap.exists) return;
      if (attempt < _verifyAttempts - 1) {
        await Future<void>.delayed(_verifyDelay);
      }
    }
    throw StateError('تعذر حفظ السجل في قاعدة البيانات');
  }

  /// Deletes [ref] then verifies absence on the server.
  static Future<void> deleteDocument(DocumentReference ref) async {
    await _ensureOnline();
    await ref.delete();
    await _awaitServerCommit();
    await verifyDeleted(ref);
  }

  /// Creates/merges [data] then verifies the document exists on the server.
  static Future<void> setDocument(
    DocumentReference ref,
    Map<String, dynamic> data, {
    SetOptions? options,
  }) async {
    await _ensureOnline();
    if (options != null) {
      await ref.set(data, options);
    } else {
      await ref.set(data);
    }
    await _awaitServerCommit();
    await verifySaved(ref);
  }

  /// Updates [ref] then verifies the document still exists on the server.
  static Future<void> updateDocument(
    DocumentReference ref,
    Map<String, dynamic> data,
  ) async {
    await _ensureOnline();
    await ref.update(data);
    await _awaitServerCommit();
    await verifySaved(ref);
  }
}
