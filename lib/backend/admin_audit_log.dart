import 'package:cloud_firestore/cloud_firestore.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_role_service.dart';

/// Single audit log row.
class AuditLogEntry {
  AuditLogEntry._(this.id, this.data);

  final String id;
  final Map<String, dynamic> data;

  factory AuditLogEntry.fromSnapshot(DocumentSnapshot snapshot) {
    return AuditLogEntry._(
      snapshot.id,
      snapshot.data() as Map<String, dynamic>? ?? {},
    );
  }

  String get action => data['action'] as String? ?? '';
  String get targetType => data['target_type'] as String? ?? '';
  String get targetLabel => data['target_label'] as String? ?? '';
  String get actorEmail => data['actor_email'] as String? ?? '';
  String get actorRole => data['actor_role'] as String? ?? '';
  Timestamp? get createdAt => data['created_at'] as Timestamp?;
}

/// Immutable audit trail for sensitive admin panel actions.
class AdminAuditLog {
  AdminAuditLog._();

  static CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection('admin_audit_log');

  /// Records an admin action (non-blocking; failures are swallowed).
  static Future<void> record({
    required String action,
    required String targetType,
    required String targetId,
    String? targetLabel,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final uid = currentUserUid;
      if (uid.isEmpty) return;

      await collection.add({
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'target_label': targetLabel ?? '',
        'actor_uid': uid,
        'actor_email': currentUserEmail,
        'actor_role': AdminRoleService.roleLabel(AdminRoleService.currentRole),
        'created_at': FieldValue.serverTimestamp(),
        if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
      }).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  static Future<void> recordDelete({
    required String targetType,
    required String targetId,
    String? targetLabel,
  }) =>
      record(
        action: 'delete',
        targetType: targetType,
        targetId: targetId,
        targetLabel: targetLabel,
      );

  static Future<void> recordToggle({
    required String targetType,
    required String targetId,
    required bool activated,
    String? targetLabel,
  }) =>
      record(
        action: activated ? 'activate' : 'deactivate',
        targetType: targetType,
        targetId: targetId,
        targetLabel: targetLabel,
        metadata: {'activated': activated},
      );

  static Future<void> recordCancel({
    required String targetType,
    required String targetId,
    String? targetLabel,
  }) =>
      record(
        action: 'cancel',
        targetType: targetType,
        targetId: targetId,
        targetLabel: targetLabel,
      );
}
