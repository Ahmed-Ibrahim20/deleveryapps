class DeliveryReportsModel {
  final bool status;
  final String message;
  final DeliveryReportsData data;

  DeliveryReportsModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory DeliveryReportsModel.fromJson(Map<String, dynamic> json) {
    return DeliveryReportsModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: DeliveryReportsData.fromJson(json['data'] ?? {}),
    );
  }
}

class DeliveryReportsData {
  final DriverInfo driverInfo;
  final int completedOrdersCount;
  final double totalDeliveryFees;
  final String applicationPercentage;
  final double applicationCommission;
  final double netProfit;
  final ReportsPeriod period;

  DeliveryReportsData({
    required this.driverInfo,
    required this.completedOrdersCount,
    required this.totalDeliveryFees,
    required this.applicationPercentage,
    required this.applicationCommission,
    required this.netProfit,
    required this.period,
  });

  factory DeliveryReportsData.fromJson(Map<String, dynamic> json) {
    return DeliveryReportsData(
      driverInfo: DriverInfo.fromJson(json['driver_info'] ?? {}),
      completedOrdersCount: json['completed_orders_count'] ?? 0,
      totalDeliveryFees: (json['total_delivery_fees'] ?? 0).toDouble(),
      applicationPercentage: json['application_percentage'] ?? '0.00',
      applicationCommission: (json['application_commission'] ?? 0).toDouble(),
      netProfit: (json['net_profit'] ?? 0).toDouble(),
      period: ReportsPeriod.fromJson(json['period'] ?? {}),
    );
  }
}

class DriverInfo {
  final int id;
  final String name;
  final String phone;
  final String commissionPercentage;

  DriverInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.commissionPercentage,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      commissionPercentage: json['commission_percentage'] ?? '0.00',
    );
  }
}

class ReportsPeriod {
  final String? startDate;
  final String? endDate;

  ReportsPeriod({
    this.startDate,
    this.endDate,
  });

  factory ReportsPeriod.fromJson(Map<String, dynamic> json) {
    return ReportsPeriod(
      startDate: json['start_date'],
      endDate: json['end_date'],
    );
  }
}

// حالات التحميل والأخطاء
enum DeliveryReportsLoadingState {
  initial,
  loading,
  loaded,
  error,
}

class DeliveryReportsError {
  final String message;
  final String? details;

  DeliveryReportsError({
    required this.message,
    this.details,
  });

  factory DeliveryReportsError.fromException(dynamic exception) {
    return DeliveryReportsError(
      message: 'حدث خطأ في جلب التقارير',
      details: exception.toString(),
    );
  }
}
