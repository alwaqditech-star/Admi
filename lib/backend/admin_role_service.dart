import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';

/// Panel access levels (`isAdminRule` on `user`):
/// - `1` → سوبر أدمن (كل الدول)
/// - `2` → وكيل دولة
/// - `3` → شريك (معالم مرتبطة بحسابه)
/// - `4` → مدير شركة نقل
enum AdminRole {
  superAdmin,
  countryAgent,
  partner,
  transportCompany,
  none,
}

class AdminRoleService {
  AdminRoleService._();

  static const int ruleSuperAdmin = 1;
  static const int ruleCountryAgent = 2;
  static const int rulePartner = 3;
  static const int ruleTransportCompany = 4;

  static AdminRole roleFrom(UserRecord? user) {
    if (user == null) return AdminRole.none;
    final rule = user.adminRuleValue;

    if (rule == ruleSuperAdmin || user.isAdmin) {
      return AdminRole.superAdmin;
    }
    if (rule == ruleCountryAgent) {
      return AdminRole.countryAgent;
    }
    if (rule == rulePartner || user.isPartner) {
      return AdminRole.partner;
    }
    if (rule == ruleTransportCompany ||
        (user.hasTransportCompany() &&
            !user.ismndob &&
            !user.isagent &&
            !user.isPartner &&
            !user.isAdmin)) {
      return AdminRole.transportCompany;
    }
    return AdminRole.none;
  }

  static AdminRole get currentRole => roleFrom(currentUserDocument);

  static bool isSuperAdminUser(UserRecord? user) =>
      roleFrom(user) == AdminRole.superAdmin;

  static bool get isSuperAdmin => currentRole == AdminRole.superAdmin;

  static bool get isCountryAgent => currentRole == AdminRole.countryAgent;

  static bool get isPartner => currentRole == AdminRole.partner;

  static bool get isTransportCompany =>
      currentRole == AdminRole.transportCompany;

  static bool get hasPanelAccess => currentRole != AdminRole.none;

  static DocumentReference? get scopedCountryRef {
    final user = currentUserDocument;
    if (user == null) return null;
    if (isCountryAgent) {
      return user.revDlohAgent;
    }
    return null;
  }

  static String get scopedCountryName {
    final user = currentUserDocument;
    if (user == null) return '';
    if (isCountryAgent) return user.dolhAgent;
    return '';
  }

  static DocumentReference? get partnerMkanRef =>
      currentUserDocument?.partnerMkanRef;

  static DocumentReference? get transportCompanyRef =>
      currentUserDocument?.transportCompany;

  static const _superAdminOnlyRoutes = {
    'AdminAddAgent',
    'EdetAgent',
    'AdminAddSuperAdmin',
    'EdetSuperAdmin',
    'AdminSuperAdmins',
    'AddDolh',
    'AdminDol',
    'AdminAgent',
    'AdminAgentReport',
    'AdminAuditLog',
    'AdminReportsHub',
    'adminRegesr',
  };

  static bool canAccessRoute(String routeName) {
    switch (currentRole) {
      case AdminRole.superAdmin:
        return routeName != 'adminRegesr';
      case AdminRole.countryAgent:
        if (_superAdminOnlyRoutes.contains(routeName)) {
          return false;
        }
        return _agentRoutes.contains(routeName);
      case AdminRole.partner:
        return _partnerRoutes.contains(routeName);
      case AdminRole.transportCompany:
        return _transportCompanyRoutes.contains(routeName);
      case AdminRole.none:
        return false;
    }
  }

  static const _agentRoutes = {
    'Home22Dashboard',
    'AdminM3alm',
    'AdminPartners',
    'AdminAddPartner',
    'Adminregion',
    'Adminvill',
    'AddReg',
    'edetReg',
    'addVill',
    'edetVill',
    'Adminuser',
    'Admindrever',
    'AdminDrivers',
    'addDrev',
    'AdminTransportCompanies',
    'AddTransportCompany',
    'EdetTransportCompany',
    'AdminALLhgZ',
    'AdminBookingDetails',
    'AdminProfits',
    'AdminSuport',
    'Settings',
    'DriverProfile',
    'AdminaddMkan',
    'AdminaddMkanCopy',
  };

  static const _partnerRoutes = {
    'PartnerBookings',
    'AdminBookingDetails',
    'Settings',
  };

  static const _transportCompanyRoutes = {
    'CompanyDrivers',
    'addDrev',
    'Settings',
    'DriverProfile',
  };

  static String homeRouteFor(AdminRole role) {
    switch (role) {
      case AdminRole.partner:
        return 'PartnerBookings';
      case AdminRole.transportCompany:
        return 'CompanyDrivers';
      case AdminRole.countryAgent:
      case AdminRole.superAdmin:
        return 'Home22Dashboard';
      case AdminRole.none:
        return 'HomePage';
    }
  }

  static String roleLabel(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return 'سوبر أدمن';
      case AdminRole.countryAgent:
        return 'وكيل الدولة';
      case AdminRole.partner:
        return 'شريك';
      case AdminRole.transportCompany:
        return 'مدير شركة نقل';
      case AdminRole.none:
        return 'غير مصرّح';
    }
  }
}
