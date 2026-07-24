import 'package:cloud_functions/cloud_functions.dart';

/// Client wrapper for Firebase Cloud Functions (no API keys in app).
class CloudFunctionsClient {
  CloudFunctionsClient._();

  static final _functions = FirebaseFunctions.instance;

  static Future<Map<String, dynamic>> createPanelUser({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    final result = await _functions.httpsCallable('createPanelUser').call({
      'email': email,
      'password': password,
      'userData': userData,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<Map<String, dynamic>> refreshMyClaims() async {
    final result = await _functions.httpsCallable('refreshMyClaims').call();
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<String?> geminiGenerateText(String prompt) async {
    final result = await _functions.httpsCallable('geminiGenerateText').call({
      'prompt': prompt,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['text'] as String?;
  }

  static Future<Map<String, dynamic>> aggregateFinancialSummary({
    String? countryPath,
    DateTime? periodStart,
  }) async {
    final result =
        await _functions.httpsCallable('aggregateFinancialSummary').call({
      if (countryPath != null) 'countryPath': countryPath,
      if (periodStart != null) 'periodStart': periodStart.toIso8601String(),
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<void> recordAuditLog({
    required String action,
    required String target,
    String details = '',
  }) async {
    await _functions.httpsCallable('recordAuditLog').call({
      'action': action,
      'target': target,
      'details': details,
    });
  }
}
