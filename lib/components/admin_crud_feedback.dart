import 'dart:async';

import 'package:flutter/material.dart';

import '/backend/admin_dashboard_invalidate.dart';
import '/components/admin_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';

enum AdminCrudAction { add, edit, delete }

/// Identifiers for list pages that should reload after CRUD.
abstract final class AdminListScope {
  static const landmarks = 'landmarks';
  static const agents = 'agents';
  static const partners = 'partners';
  static const countries = 'countries';
  static const regions = 'regions';
  static const cities = 'cities';
  static const users = 'users';
  static const drivers = 'drivers';
  static const representatives = 'representatives';
  static const transportCompanies = 'transport_companies';
  static const support = 'support';
  static const bookings = 'bookings';
  static const superAdmins = 'super_admins';
  static const typeCars = 'type_cars';
  static const auditLog = 'audit_log';
}

/// Notifies registered [AdminFirestoreList] instances to reload.
class AdminListRefresh {
  AdminListRefresh._();

  static final Map<String, Set<VoidCallback>> _listeners = {};
  static final Map<String, Set<void Function(String docId)>> _removeListeners =
      {};

  static void register(String scope, VoidCallback listener) {
    _listeners.putIfAbsent(scope, () => {}).add(listener);
  }

  static void unregister(String scope, VoidCallback listener) {
    _listeners[scope]?.remove(listener);
  }

  static void registerRemove(
    String scope,
    void Function(String docId) listener,
  ) {
    _removeListeners.putIfAbsent(scope, () => {}).add(listener);
  }

  static void unregisterRemove(
    String scope,
    void Function(String docId) listener,
  ) {
    _removeListeners[scope]?.remove(listener);
  }

  static void removeItem(String scope, String docId) {
    final listeners = _removeListeners[scope];
    if (listeners == null || listeners.isEmpty) return;
    for (final listener in List<void Function(String)>.from(listeners)) {
      listener(docId);
    }
  }

  static void notify(String scope, {bool immediate = false}) {
    final listeners = _listeners[scope];
    if (listeners == null || listeners.isEmpty) return;

    void run() {
      final current = _listeners[scope];
      if (current == null) return;
      for (final listener in List<VoidCallback>.from(current)) {
        listener();
      }
    }

    if (immediate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => run());
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 200), run);
    });
  }

  static void notifyAll({bool immediate = false}) {
    for (final scope in _listeners.keys.toList()) {
      notify(scope, immediate: immediate);
    }
  }
}

/// Unified popup feedback + list refresh after add / edit / delete.
abstract final class AdminCrudFeedback {
  AdminCrudFeedback._();

  static const String deleteSuccessMessage = 'تم الحذف بنجاح';

  static String defaultMessage(AdminCrudAction action) {
    switch (action) {
      case AdminCrudAction.add:
        return 'تمت الإضافة بنجاح';
      case AdminCrudAction.edit:
        return 'تم حفظ التعديلات بنجاح';
      case AdminCrudAction.delete:
        return deleteSuccessMessage;
    }
  }

  static IconData _icon(AdminCrudAction action) {
    switch (action) {
      case AdminCrudAction.add:
        return Icons.add_circle_outline_rounded;
      case AdminCrudAction.edit:
        return Icons.edit_note_rounded;
      case AdminCrudAction.delete:
        return Icons.delete_outline_rounded;
    }
  }

  static void _showSnackSuccess(
    BuildContext context, {
    required AdminCrudAction action,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context) ??
        ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AdminUi.brandTeal,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: duration,
        content: Row(
          children: [
            Icon(_icon(action), color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  fontFamily: 'cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Blocking success popup — shown immediately on root navigator.
  static Future<void> _showDeleteSuccessDialog(String message) async {
    final navContext = appNavigatorKey.currentContext;
    if (navContext == null || !navContext.mounted) return;

    await showDialog<void>(
      context: navContext,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogCtx) {
        Future<void>.delayed(const Duration(milliseconds: 2400), () {
          if (dialogCtx.mounted) {
            Navigator.of(dialogCtx, rootNavigator: true).pop();
          }
        });
        return PopScope(
          canPop: true,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminUi.radiusMd),
            ),
            elevation: 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AdminUi.brandTeal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AdminUi.brandTeal,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B4332),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> success(
    BuildContext context, {
    required AdminCrudAction action,
    String? message,
    String? refreshScope,
    Iterable<String>? refreshScopes,
    String? removedDocumentId,
    Future<void> Function()? refresh,
    bool invalidateStats = true,
    bool popPage = false,
    bool? deferHeavyWork,
  }) async {
    if (!context.mounted) return;

    final text = message ?? defaultMessage(action);
    final isDelete = action == AdminCrudAction.delete;
    final deleteMessage =
        isDelete ? (message ?? deleteSuccessMessage) : text;
    final shouldDefer = deferHeavyWork ?? !isDelete;

    final scopes = <String>{
      ...?refreshScopes,
      if (refreshScope != null) refreshScope,
    };

    void refreshLists({required bool immediate, bool removeRow = false}) {
      if (removeRow && removedDocumentId != null) {
        for (final scope in scopes) {
          AdminListRefresh.removeItem(scope, removedDocumentId);
        }
      }
      for (final scope in scopes) {
        AdminListRefresh.notify(scope, immediate: immediate);
      }
      if (refresh != null) {
        unawaited(refresh());
      }
    }

    if (isDelete) {
      // 1) Popup first — always visible.
      if (context.mounted) {
        _showSnackSuccess(
          context,
          action: AdminCrudAction.delete,
          message: deleteMessage,
          duration: const Duration(seconds: 4),
        );
      }
      unawaited(_showDeleteSuccessDialog(deleteMessage));

      // 2) Remove row + reload current list from server.
      refreshLists(immediate: true, removeRow: true);

      // 3) Refresh dashboard stats immediately.
      if (invalidateStats) {
        refreshDashboardStatsAfterDelete(
          refreshScope: refreshScope,
          refreshScopes: refreshScopes,
        );
      }

      if (popPage && context.mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (context.mounted) context.safePop();
      }
      return;
    }

    _showSnackSuccess(context, action: action, message: text);
    if (shouldDefer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(
          const Duration(milliseconds: 200),
          () => refreshLists(immediate: false),
        );
      });
    } else {
      refreshLists(immediate: true);
    }

    if (invalidateStats) {
      if (!shouldDefer) {
        invalidateAdminDashboardStats();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future<void>.delayed(
            const Duration(milliseconds: 200),
            invalidateAdminDashboardStats,
          );
        });
      }
    }

    if (popPage && context.mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (context.mounted) context.safePop();
    }
  }

  static void error(BuildContext context, String message) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFC62828),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void validation(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFEF6C00),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminUi.radiusSm),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        content: Text(message),
      ),
    );
  }
}
