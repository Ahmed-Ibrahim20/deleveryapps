import '../api_service.dart';
import 'package:dio/dio.dart';
import 'package:my_app_delevery1/services/Auth/token_storage.dart';

class ComplaintService extends ApiService {
  ComplaintService()
    : super(baseUrl: 'http://127.0.0.1:8000/api/v1/dashboard');

  // جلب جميع الشكاوى
  Future<Response> getAllComplaints({int? page}) async {
    final headers = await _getHeaders();
    String url = '$baseUrl/complaints';
    if (page != null) url += "?page=$page";

    print("🔍 GET All Complaints: $url");
    print("🔑 Headers: $headers");

    try {
      return await dio.get(url, options: Options(headers: headers));
    } on DioException catch (e) {
      print("❌ DioError [GET Complaints]: ${e.message}");
      print("❌ Status Code: ${e.response?.statusCode}");
      print("❌ Response Data: ${e.response?.data}");
      rethrow;
    }
  }

  // إرسال شكوى جديدة
  Future<Response> createComplaint(String complaintText) async {
    final headers = await _getHeaders();
    final data = {
      'complaint_text': complaintText,
    };

    final url = '$baseUrl/complaints';
    print("🚀 POST Create Complaint: $url");
    print("📝 Data: $data");
    print("🔑 Headers: $headers");

    try {
      return await dio.post(
        url,
        data: data,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      print("❌ DioError [Create Complaint]: ${e.message}");
      print("❌ Status Code: ${e.response?.statusCode}");
      print("❌ Response Data: ${e.response?.data}");
      rethrow;
    }
  }

  // حذف شكوى
  Future<Response> deleteComplaint(dynamic complaintId) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/complaints/$complaintId';

    print("🗑️ DELETE Complaint: $url");
    print("🔑 Headers: $headers");

    try {
      return await dio.delete(url, options: Options(headers: headers));
    } on DioException catch (e) {
      print("❌ DioError [Delete Complaint]: ${e.message}");
      print("❌ Status Code: ${e.response?.statusCode}");
      print("❌ Response Data: ${e.response?.data}");
      rethrow;
    }
  }

  // الحصول على headers مع التوكن
  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    
    print("🔐 Token Check:");
    print("📱 Token exists: ${token != null}");
    print("📏 Token length: ${token?.length ?? 0}");
    if (token != null && token.isNotEmpty) {
      print("✅ Token will be sent: Bearer ${token.substring(0, 20)}...");
    } else {
      print("❌ No token found! User might not be logged in.");
    }
    
    final headers = {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    
    print("📋 Final Headers: $headers");
    return headers;
  }
}
