import '../api_service.dart';
import 'package:dio/dio.dart';
import 'package:my_app_delevery1/services/Auth/token_storage.dart';

class ReportsService extends ApiService {
  ReportsService()
      : super(baseUrl: 'http://127.0.0.1:8000/api/v1/dashboard/reports');

  /// جلب تقارير الأدمن الشاملة مع فلترة التواريخ
  /// [startDate] تاريخ البداية بصيغة YYYY-MM-DD
  /// [endDate] تاريخ النهاية بصيغة YYYY-MM-DD
  Future<Response> getAdminReports({
    String? startDate,
    String? endDate,
  }) async {
    final headers = await _getHeaders();
    
    // بناء URL مع المعاملات
    String url = '$baseUrl/admin';
    List<String> queryParams = [];
    
    if (startDate != null && startDate.isNotEmpty) {
      queryParams.add('start_date=$startDate');
    }
    
    if (endDate != null && endDate.isNotEmpty) {
      queryParams.add('end_date=$endDate');
    }
    
    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    print("🔍 GET Admin Reports: $url");
    print("📋 Headers: $headers");

    try {
      final response = await dio.get(url, options: Options(headers: headers));
      print("✅ Admin Reports Response: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      print("❌ DioError [GET Admin Reports]: ${e.message}");
      print("📊 Response Data: ${e.response?.data}");
      rethrow;
    }
  }

  /// جلب تقارير المتاجر
  Future<Response> getShopReports({
    String? startDate,
    String? endDate,
    int? shopId,
  }) async {
    final headers = await _getHeaders();
    
    String url = '$baseUrl/shop';
    List<String> queryParams = [];
    
    if (startDate != null && startDate.isNotEmpty) {
      queryParams.add('start_date=$startDate');
    }
    
    if (endDate != null && endDate.isNotEmpty) {
      queryParams.add('end_date=$endDate');
    }
    
    if (shopId != null) {
      queryParams.add('shop_id=$shopId');
    }
    
    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    print("🏪 GET Shop Reports: $url");
    print("📋 Headers: $headers");

    try {
      final response = await dio.get(url, options: Options(headers: headers));
      print("✅ Shop Reports Response: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      print("❌ DioError [GET Shop Reports]: ${e.message}");
      rethrow;
    }
  }

  /// جلب تقارير السائقين
  Future<Response> getDriverReports({
    String? startDate,
    String? endDate,
    int? driverId,
  }) async {
    final headers = await _getHeaders();
    
    String url = '$baseUrl/driver';
    List<String> queryParams = [];
    
    if (startDate != null && startDate.isNotEmpty) {
      queryParams.add('start_date=$startDate');
    }
    
    if (endDate != null && endDate.isNotEmpty) {
      queryParams.add('end_date=$endDate');
    }
    
    if (driverId != null) {
      queryParams.add('driver_id=$driverId');
    }
    
    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    print("🚗 GET Driver Reports: $url");
    print("📋 Headers: $headers");

    try {
      final response = await dio.get(url, options: Options(headers: headers));
      print("✅ Driver Reports Response: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      print("❌ DioError [GET Driver Reports]: ${e.message}");
      rethrow;
    }
  }

  /// جلب تقارير الطلبات
  Future<Response> getOrdersReports({
    String? startDate,
    String? endDate,
    int? status,
  }) async {
    final headers = await _getHeaders();
    
    String url = '$baseUrl/orders';
    List<String> queryParams = [];
    
    if (startDate != null && startDate.isNotEmpty) {
      queryParams.add('start_date=$startDate');
    }
    
    if (endDate != null && endDate.isNotEmpty) {
      queryParams.add('end_date=$endDate');
    }
    
    if (status != null) {
      queryParams.add('status=$status');
    }
    
    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    print("📦 GET Orders Reports: $url");
    print("📋 Headers: $headers");

    try {
      final response = await dio.get(url, options: Options(headers: headers));
      print("✅ Orders Reports Response: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      print("❌ DioError [GET Orders Reports]: ${e.message}");
      rethrow;
    }
  }

  /// تصدير التقارير كـ PDF
  Future<Response> exportReportsPDF({
    String? startDate,
    String? endDate,
    String reportType = 'admin', // admin, shop, driver, orders
  }) async {
    final headers = await _getHeaders();
    
    String url = '$baseUrl/export/pdf';
    List<String> queryParams = [];
    
    queryParams.add('type=$reportType');
    
    if (startDate != null && startDate.isNotEmpty) {
      queryParams.add('start_date=$startDate');
    }
    
    if (endDate != null && endDate.isNotEmpty) {
      queryParams.add('end_date=$endDate');
    }
    
    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    print("📄 GET Export PDF: $url");
    print("📋 Headers: $headers");

    try {
      final response = await dio.get(
        url, 
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes, // للملفات
        ),
      );
      print("✅ Export PDF Response: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      print("❌ DioError [Export PDF]: ${e.message}");
      rethrow;
    }
  }

  /// جلب إحصائيات سريعة للداشبورد
  Future<Response> getDashboardStats() async {
    final headers = await _getHeaders();
    final url = '$baseUrl/dashboard/stats';

    print("📊 GET Dashboard Stats: $url");
    print("📋 Headers: $headers");

    try {
      final response = await dio.get(url, options: Options(headers: headers));
      print("✅ Dashboard Stats Response: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      print("❌ DioError [GET Dashboard Stats]: ${e.message}");
      rethrow;
    }
  }

  /// الحصول على headers مع التوكن
  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}
