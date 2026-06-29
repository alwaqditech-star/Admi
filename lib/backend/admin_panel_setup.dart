import 'package:flutter/foundation.dart';

import '/app_state.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/admin_country_backfill.dart';
import '/backend/admin_landmark_country_backfill.dart';
import '/backend/admin_partner_order_backfill.dart';
import '/backend/admin_production_landmark_seed.dart';
import '/backend/admin_role_service.dart';

/// One-time post-login maintenance for production readiness.
class AdminPanelSetup {
  AdminPanelSetup._();

  static const _partnerMkansKey = 'admin_setup_partner_mkans_v1';
  static const _countryFieldsKey = 'admin_setup_country_fields_v3';
  static const _landmarkCountryKey = 'admin_setup_landmark_country_v4';
  static const _productionSeedKey = 'admin_production_landmark_seed_v3';

  /// Runs background setup after login (non-blocking).
  static Future<void> runPostLoginTasks() async {
    if (!loggedIn || !AdminRoleService.hasPanelAccess) return;

    if (AdminRoleService.isSuperAdmin) {
      await _runOncePerUser(_productionSeedKey, () async {
        final result = await AdminProductionLandmarkSeed.runAuthenticated();
        if (!result.success) {
          debugPrint('Production seed failed: ${result.error}');
        } else {
          debugPrint(
            'Production seed OK: ${result.landmarks} landmarks, ${result.orders} orders',
          );
        }
      });
      await _runOncePerUser(_partnerMkansKey, () async {
        await AdminPartnerOrderBackfill.run(activeOnly: true);
      });
      await _runOncePerUser(_countryFieldsKey, () async {
        await AdminCountryBackfill.run();
      });
    }

    if (AdminRoleService.isCountryAgent) {
      await _runOncePerUser(_landmarkCountryKey, () async {
        final result = await AdminLandmarkCountryBackfill.syncCurrentAgentCountry();
        if (!result.success) {
          debugPrint('Saudi landmark link failed: ${result.error}');
        } else {
          debugPrint(
            'Saudi landmark link OK: ${result.landmarks} landmarks, '
            '${result.agents} agents',
          );
        }
      });
    }
  }

  static Future<void> _runOncePerUser(
    String taskKey,
    Future<void> Function() task,
  ) async {
    try {
      final prefs = FFAppState().prefs;
      final uid = currentUserUid;
      if (uid.isEmpty) return;

      final storageKey = '${taskKey}_$uid';
      if (prefs.getBool(storageKey) == true) return;

      await task().timeout(const Duration(minutes: 3));
      await prefs.setBool(storageKey, true);
    } catch (_) {
      // Retry on next login if setup did not complete.
    }
  }

  /// Forces partner_mkans backfill (settings button).
  static Future<PartnerOrderBackfillResult> runPartnerOrderBackfill() =>
      AdminPartnerOrderBackfill.run(activeOnly: true);

  /// Marks partner backfill as pending again (after manual trigger).
  static Future<void> resetPartnerMkansFlag() async {
    final prefs = FFAppState().prefs;
    final uid = currentUserUid;
    if (uid.isEmpty) return;
    await prefs.remove('${_partnerMkansKey}_$uid');
  }
}
