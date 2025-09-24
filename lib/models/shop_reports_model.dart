class ShopReportsModel {
  final bool status;
  final String message;
  final ShopReportsData data;

  ShopReportsModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ShopReportsModel.fromJson(Map<String, dynamic> json) {
    return ShopReportsModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: ShopReportsData.fromJson(json['data'] ?? {}),
    );
  }
}

class ShopReportsData {
  final ShopInfo shopInfo;
  final int completedOrdersCount;
  final double totalOrdersValue;
  final double totalDeliveryFees;
  final String applicationPercentage;
  final double applicationCommission;
  final double netProfit;
  final ShopReportsPeriod period;

  ShopReportsData({
    required this.shopInfo,
    required this.completedOrdersCount,
    required this.totalOrdersValue,
    required this.totalDeliveryFees,
    required this.applicationPercentage,
    required this.applicationCommission,
    required this.netProfit,
    required this.period,
  });

  factory ShopReportsData.fromJson(Map<String, dynamic> json) {
    return ShopReportsData(
      shopInfo: ShopInfo.fromJson(json['shop_info'] ?? {}),
      completedOrdersCount: json['completed_orders_count'] ?? 0,
      totalOrdersValue: (json['total_orders_value'] ?? 0).toDouble(),
      totalDeliveryFees: (json['total_delivery_fees'] ?? 0).toDouble(),
      applicationPercentage: json['application_percentage'] ?? '0.00',
      applicationCommission: (json['application_commission'] ?? 0).toDouble(),
      netProfit: (json['net_profit'] ?? 0).toDouble(),
      period: ShopReportsPeriod.fromJson(json['period'] ?? {}),
    );
  }
}

class ShopInfo {
  final int id;
  final String name;
  final String phone;
  final String commissionPercentage;

  ShopInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.commissionPercentage,
  });

  factory ShopInfo.fromJson(Map<String, dynamic> json) {
    return ShopInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      commissionPercentage: json['commission_percentage'] ?? '0.00',
    );
  }
}

class ShopReportsPeriod {
  final String? startDate;
  final String? endDate;

  ShopReportsPeriod({
    this.startDate,
    this.endDate,
  });

  factory ShopReportsPeriod.fromJson(Map<String, dynamic> json) {
    return ShopReportsPeriod(
      startDate: json['start_date'],
      endDate: json['end_date'],
    );
  }
}

// حالات التحميل والأخطاء
enum ShopReportsLoadingState {
  initial,
  loading,
  loaded,
  error,
}

class ShopReportsError {
  final String message;
  final String? details;

  ShopReportsError({
    required this.message,
    this.details,
  });

  factory ShopReportsError.fromException(dynamic exception) {
    return ShopReportsError(
      message: 'حدث خطأ في جلب التقارير',
      details: exception.toString(),
    );
  }
}
