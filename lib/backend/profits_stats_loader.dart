import '/backend/admin_country_scope.dart';
import '/backend/admin_performance.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';

/// Time window for profits dashboard filters.
enum ProfitsPeriod {
  today,
  week,
  month,
  year,
  all,
}

extension ProfitsPeriodLabel on ProfitsPeriod {
  String get arabicLabel => switch (this) {
        ProfitsPeriod.today => 'اليوم',
        ProfitsPeriod.week => '7 أيام',
        ProfitsPeriod.month => 'هذا الشهر',
        ProfitsPeriod.year => 'هذه السنة',
        ProfitsPeriod.all => 'الكل',
      };
}

/// One bar in the monthly revenue chart.
class ProfitsMonthlyPoint {
  const ProfitsMonthlyPoint({
    required this.month,
    required this.label,
    required this.sales,
    required this.appProfit,
    required this.orderCount,
  });

  final DateTime month;
  final String label;
  final double sales;
  final double appProfit;
  final int orderCount;
}

/// Recent order row for the transactions list.
class ProfitsOrderRow {
  const ProfitsOrderRow({required this.order});

  final OrderRecord order;
}

/// Aggregated profits metrics from Firestore orders.
class ProfitsSummary {
  const ProfitsSummary({
    required this.totalSales,
    required this.appProfit,
    required this.vat,
    required this.repCommission,
    required this.deliveryFees,
    required this.orderCount,
    required this.paidCount,
    required this.pendingCount,
    required this.canceledCount,
    required this.monthlyTrend,
    required this.recentOrders,
    required this.period,
    required this.loadedAt,
  });

  final double totalSales;
  final double appProfit;
  final double vat;
  final double repCommission;
  final double deliveryFees;
  final int orderCount;
  final int paidCount;
  final int pendingCount;
  final int canceledCount;
  final List<ProfitsMonthlyPoint> monthlyTrend;
  final List<ProfitsOrderRow> recentOrders;
  final ProfitsPeriod period;
  final DateTime loadedAt;

  double get platformFees => appProfit + vat;

  double get partnerPayouts => repCommission + deliveryFees;

  bool get isExpired =>
      DateTime.now().difference(loadedAt) > const Duration(minutes: 3);
}

DateTime? _periodStart(ProfitsPeriod period) {
  final now = DateTime.now();
  return switch (period) {
    ProfitsPeriod.today => DateTime(now.year, now.month, now.day),
    ProfitsPeriod.week => now.subtract(const Duration(days: 7)),
    ProfitsPeriod.month => DateTime(now.year, now.month, 1),
    ProfitsPeriod.year => DateTime(now.year, 1, 1),
    ProfitsPeriod.all => null,
  };
}

bool _isCanceled(OrderRecord order) {
  if (order.halhOrder == Halh.Canceled) {
    return true;
  }
  return order.halh.toLowerCase() == 'canceled';
}

bool _isPaid(OrderRecord order) {
  if (order.halhOrder == Halh.Paid) {
    return true;
  }
  return order.halh.toLowerCase() == 'paid';
}

bool _isPending(OrderRecord order) {
  if (_isCanceled(order) || _isPaid(order)) {
    return false;
  }
  if (order.halhOrder == Halh.Pending) {
    return true;
  }
  return order.halh.toLowerCase() == 'pending';
}

bool _countsTowardRevenue(OrderRecord order) => !_isCanceled(order);

String _monthLabel(DateTime month) {
  const labels = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  return labels[month.month - 1];
}

List<ProfitsMonthlyPoint> _buildMonthlyTrend(List<OrderRecord> orders) {
  final now = DateTime.now();
  final months = List.generate(6, (i) {
    final m = DateTime(now.year, now.month - (5 - i), 1);
    return DateTime(m.year, m.month, 1);
  });

  return months.map((monthStart) {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
    var sales = 0.0;
    var appProfit = 0.0;
    var count = 0;

    for (final order in orders) {
      if (!_countsTowardRevenue(order)) {
        continue;
      }
      final date = order.dataOrder;
      if (date == null) {
        continue;
      }
      if (!date.isBefore(monthEnd) || date.isBefore(monthStart)) {
        continue;
      }
      count++;
      sales += order.total;
      appProfit += order.totalApp.toDouble();
    }

    return ProfitsMonthlyPoint(
      month: monthStart,
      label: _monthLabel(monthStart),
      sales: sales,
      appProfit: appProfit,
      orderCount: count,
    );
  }).toList();
}

/// Loads orders for profits with server-side date filter + pagination cap.
Future<ProfitsSummary> loadProfitsStats({
  ProfitsPeriod period = ProfitsPeriod.month,
}) async {
  final start = _periodStart(period);
  final orderLimit = start == null ? 250 : 150;

  final orders = AdminCountryScope.filterOrders(
    await queryListCacheFirst<OrderRecord>(
      OrderRecord.collection,
      OrderRecord.fromSnapshot,
      queryBuilder: (q) {
        var query = AdminCountryScope.applyOrderQuery(q)
            .orderBy('data_order', descending: true);
        if (start != null) {
          query = query.where('data_order', isGreaterThanOrEqualTo: start);
        }
        return query;
      },
      limit: orderLimit,
    ),
  );

  final filtered = orders;

  var totalSales = 0.0;
  var appProfit = 0.0;
  var vat = 0.0;
  var repCommission = 0.0;
  var deliveryFees = 0.0;
  var paidCount = 0;
  var pendingCount = 0;
  var canceledCount = 0;

  for (final order in filtered) {
    if (_isCanceled(order)) {
      canceledCount++;
      continue;
    }

    if (_isPaid(order)) {
      paidCount++;
    } else if (_isPending(order)) {
      pendingCount++;
    }

    totalSales += order.total;
    appProfit += order.totalApp.toDouble();
    vat += order.totalVat.toDouble();
    repCommission += order.totalMndob.toDouble();
    deliveryFees += order.totalMndob2.toDouble();
  }

  final recent = filtered
      .where(_countsTowardRevenue)
      .take(12)
      .map((order) => ProfitsOrderRow(order: order))
      .toList();

  return ProfitsSummary(
    totalSales: totalSales,
    appProfit: appProfit,
    vat: vat,
    repCommission: repCommission,
    deliveryFees: deliveryFees,
    orderCount: filtered.length,
    paidCount: paidCount,
    pendingCount: pendingCount,
    canceledCount: canceledCount,
    monthlyTrend: _buildMonthlyTrend(orders),
    recentOrders: recent,
    period: period,
    loadedAt: DateTime.now(),
  );
}
