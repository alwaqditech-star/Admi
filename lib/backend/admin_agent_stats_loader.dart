import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';

/// Booking metrics for an agent's country scope (from Firestore `order`).
class AgentReportStats {
  const AgentReportStats({
    required this.totalBookings,
    required this.activeBookings,
    required this.paidBookings,
    required this.completionRate,
    required this.totalSales,
    required this.commissionEarned,
    required this.recentOrders,
  });

  final int totalBookings;
  final int activeBookings;
  final int paidBookings;
  final double completionRate;
  final double totalSales;
  final double commissionEarned;
  final List<OrderRecord> recentOrders;

  static const empty = AgentReportStats(
    totalBookings: 0,
    activeBookings: 0,
    paidBookings: 0,
    completionRate: 0,
    totalSales: 0,
    commissionEarned: 0,
    recentOrders: [],
  );
}

bool _isCanceled(OrderRecord order) {
  if (order.halhOrder == Halh.Canceled) return true;
  return order.halh.toLowerCase() == 'canceled';
}

bool _isPaid(OrderRecord order) {
  if (order.halhOrder == Halh.Paid) return true;
  return order.halh.toLowerCase() == 'paid';
}

String orderDisplayTitle(OrderRecord order) {
  if (order.cartext.isNotEmpty) return order.cartext;
  if (order.villText.isNotEmpty) return order.villText;
  if (order.iDorder.isNotEmpty) return order.iDorder;
  if (order.naimUserText.isNotEmpty) return order.naimUserText;
  return 'حجز';
}

/// Loads agent performance from orders in the agent's country (`Rev_dolh`).
Future<AgentReportStats> loadAgentReportStats(UserRecord agent) async {
  final countryRef = agent.revDlohAgent;
  if (countryRef == null) {
    return AgentReportStats.empty;
  }

  final orders = await queryOrderRecordOnce(
    queryBuilder: (q) => q
        .where('Rev_dolh', isEqualTo: countryRef)
        .orderBy('data_order', descending: true),
    limit: 500,
  );

  var totalSales = 0.0;
  var activeBookings = 0;
  var paidBookings = 0;
  var canceledBookings = 0;

  for (final order in orders) {
    if (order.allnow) activeBookings++;
    if (_isPaid(order)) {
      paidBookings++;
      totalSales += order.total;
    } else if (_isCanceled(order)) {
      canceledBookings++;
    }
  }

  final decided = paidBookings + canceledBookings;
  final completionRate =
      decided == 0 ? 0.0 : (paidBookings / decided) * 100.0;

  final commissionPercent = agent.agentTotal;
  final commissionEarned =
      commissionPercent > 0 ? totalSales * commissionPercent / 100.0 : 0.0;

  return AgentReportStats(
    totalBookings: orders.length,
    activeBookings: activeBookings,
    paidBookings: paidBookings,
    completionRate: completionRate,
    totalSales: totalSales,
    commissionEarned: commissionEarned,
    recentOrders: orders.take(10).toList(),
  );
}
