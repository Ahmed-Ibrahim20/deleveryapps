import '../api_service.dart';
import 'package:dio/dio.dart';
import 'package:my_app_delevery1/services/Auth/token_storage.dart';

class ShopReportsService extends ApiService {
  ShopReportsService()
      : super(baseUrl: 'http://127.0.0.1:8000/api/v1/dashboard/reports');

  /// جلب تقارير المتجر مع فلترة التواريخ
  /// [startDate] تاريخ البداية بصيغة YYYY-MM-DD
  /// [endDate] تاريخ النهاية بصيغة YYYY-MM-DD
  Future<Response> getMyShopReports({
    String? startDate,
    String? endDate,
  }) async {
    final headers = await _getHeaders();
    
    // بناء URL مع المعاملات
    String url = '$baseUrl/my-shop';
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

    print("📊 GET Shop Reports: $url");
    print("📋 Headers: $headers");

    try {
      final response = await dio.get(url, options: Options(headers: headers));
      print("✅ Shop Reports Response: ${response.statusCode}");
      return response;
    } on DioException catch (e) {
      print("❌ DioError [GET Shop Reports]: ${e.message}");
      print("📊 Response Data: ${e.response?.data}");
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
