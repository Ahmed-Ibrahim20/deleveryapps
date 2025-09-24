class AdminReportsModel {
  final bool status;
  final String message;
  final AdminReportsData data;

  AdminReportsModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory AdminReportsModel.fromJson(Map<String, dynamic> json) {
    return AdminReportsModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: AdminReportsData.fromJson(json['data'] ?? {}),
    );
  }
}

class AdminReportsData {
  final ReportsSummary summary;
  final GeneralStatistics generalStatistics;
  final TopPerformance topPerformance;

  AdminReportsData({
    required this.summary,
    required this.generalStatistics,
    required this.topPerformance,
  });

  factory AdminReportsData.fromJson(Map<String, dynamic> json) {
    return AdminReportsData(
      summary: ReportsSummary.fromJson(json['summary'] ?? {}),
      generalStatistics: GeneralStatistics.fromJson(json['general_statistics'] ?? {}),
      topPerformance: TopPerformance.fromJson(json['top_performance'] ?? {}),
    );
  }
}

class ReportsSummary {
  final int completedOrdersCount;
  final double totalOrdersValue;
  final double totalDeliveryFees;
  final double shopCommissionTotal;
  final double driverCommissionTotal;
  final double totalPlatformRevenue;
  final ReportsPeriod period;

  ReportsSummary({
    required this.completedOrdersCount,
    required this.totalOrdersValue,
    required this.totalDeliveryFees,
    required this.shopCommissionTotal,
    required this.driverCommissionTotal,
    required this.totalPlatformRevenue,
    required this.period,
  });

  factory ReportsSummary.fromJson(Map<String, dynamic> json) {
    return ReportsSummary(
      completedOrdersCount: json['completed_orders_count'] ?? 0,
      totalOrdersValue: (json['total_orders_value'] ?? 0).toDouble(),
      totalDeliveryFees: (json['total_delivery_fees'] ?? 0).toDouble(),
      shopCommissionTotal: (json['shop_commission_total'] ?? 0).toDouble(),
      driverCommissionTotal: (json['driver_commission_total'] ?? 0).toDouble(),
      totalPlatformRevenue: (json['total_platform_revenue'] ?? 0).toDouble(),
      period: ReportsPeriod.fromJson(json['period'] ?? {}),
    );
  }
}

class ReportsPeriod {
  final String startDate;
  final String endDate;

  ReportsPeriod({
    required this.startDate,
    required this.endDate,
  });

  factory ReportsPeriod.fromJson(Map<String, dynamic> json) {
    return ReportsPeriod(
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
    );
  }
}

class GeneralStatistics {
  final int totalShopsCount;
  final int totalDriversCount;
  final int activeShopsCount;
  final int activeDriversCount;

  GeneralStatistics({
    required this.totalShopsCount,
    required this.totalDriversCount,
    required this.activeShopsCount,
    required this.activeDriversCount,
  });

  factory GeneralStatistics.fromJson(Map<String, dynamic> json) {
    return GeneralStatistics(
      totalShopsCount: json['total_shops_count'] ?? 0,
      totalDriversCount: json['total_drivers_count'] ?? 0,
      activeShopsCount: json['active_shops_count'] ?? 0,
      activeDriversCount: json['active_drivers_count'] ?? 0,
    );
  }
}

class TopPerformance {
  final List<TopShop> topShops;
  final List<TopDriver> topDrivers;

  TopPerformance({
    required this.topShops,
    required this.topDrivers,
  });

  factory TopPerformance.fromJson(Map<String, dynamic> json) {
    return TopPerformance(
      topShops: (json['top_shops'] as List<dynamic>?)
          ?.map((item) => TopShop.fromJson(item))
          .toList() ?? [],
      topDrivers: (json['top_drivers'] as List<dynamic>?)
          ?.map((item) => TopDriver.fromJson(item))
          .toList() ?? [],
    );
  }
}

class TopShop {
  final int id;
  final String name;
  final String phone;
  final String commissionPercentage;
  final int ordersCount;
  final double totalOrdersValue;
  final double commissionPaidToPlatform;

  TopShop({
    required this.id,
    required this.name,
    required this.phone,
    required this.commissionPercentage,
    required this.ordersCount,
    required this.totalOrdersValue,
    required this.commissionPaidToPlatform,
  });

  factory TopShop.fromJson(Map<String, dynamic> json) {
    return TopShop(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      commissionPercentage: json['commission_percentage'] ?? '0.00',
      ordersCount: json['orders_count'] ?? 0,
      totalOrdersValue: (json['total_orders_value'] ?? 0).toDouble(),
      commissionPaidToPlatform: (json['commission_paid_to_platform'] ?? 0).toDouble(),
    );
  }
}

class TopDriver {
  final int id;
  final String name;
  final String phone;
  final String commissionPercentage;
  final int ordersCount;
  final double totalDeliveryFees;
  final double commissionPaidToPlatform;

  TopDriver({
    required this.id,
    required this.name,
    required this.phone,
    required this.commissionPercentage,
    required this.ordersCount,
    required this.totalDeliveryFees,
    required this.commissionPaidToPlatform,
  });

  factory TopDriver.fromJson(Map<String, dynamic> json) {
    return TopDriver(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      commissionPercentage: json['commission_percentage'] ?? '0.00',
      ordersCount: json['orders_count'] ?? 0,
      totalDeliveryFees: (json['total_delivery_fees'] ?? 0).toDouble(),
      commissionPaidToPlatform: (json['commission_paid_to_platform'] ?? 0).toDouble(),
    );
  }
}

// نموذج لحالات التحميل والأخطاء
enum ReportsLoadingState {
  initial,
  loading,
  loaded,
  error,
}

class ReportsError {
  final String message;
  final String? details;
  final int? statusCode;

  ReportsError({
    required this.message,
    this.details,
    this.statusCode,
  });

  factory ReportsError.fromException(dynamic exception) {
    if (exception.toString().contains('SocketException')) {
      return ReportsError(
        message: 'خطأ في الاتصال بالإنترنت',
        details: 'تأكد من اتصالك بالإنترنت وحاول مرة أخرى',
      );
    } else if (exception.toString().contains('TimeoutException')) {
      return ReportsError(
        message: 'انتهت مهلة الاتصال',
        details: 'الخادم لا يستجيب، حاول مرة أخرى',
      );
    } else {
      return ReportsError(
        message: 'حدث خطأ غير متوقع',
        details: exception.toString(),
      );
    }
  }
}
