import '../api_service.dart';
import 'package:dio/dio.dart';
import 'package:my_app_delevery1/services/Auth/token_storage.dart';

class UserService extends ApiService {
  UserService()
    : super(baseUrl: 'http://127.0.0.1:8000/api/v1/dashboard/users');

  // جلب المستخدمين غير المعتمدين (is_approved = false)
  Future<Response> getPendingUsers({int? page}) async {
    final headers = await _getHeaders();
    String url = baseUrl; // استخدام endpoint الأساسي للمستخدمين
    if (page != null) url += "?page=$page";

    print(" GET Pending Users: $url");
    print(" Headers: $headers");

    try {
      return await dio.get(url, options: Options(headers: headers));
    } on DioException catch (e) {
      print(" DioError [GET Pending Users]: ${e.message}");
      rethrow;
    }
  }

  // جلب جميع المستخدمين
  Future<Response> getAllUsers({int? page}) async {
    final headers = await _getHeaders();
    String url = '$baseUrl'; // endpoint لجلب جميع المستخدمين
    if (page != null) url += "?page=$page";

    print(" GET All Users: $url");
    print(" Headers: $headers");

    try {
      return await dio.get(url, options: Options(headers: headers));
    } on DioException catch (e) {
      print(" DioError [GET All Users]: ${e.message}");
      rethrow;
    }
  }

  // حذف مستخدم
  Future<Response> deleteUser(dynamic userId) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/$userId';

    print(" DELETE User: $url");
    print(" Headers: $headers");

    try {
      return await dio.delete(url, options: Options(headers: headers));
    } on DioException catch (e) {
      print(" DioError [Delete User]: ${e.message}");
      rethrow;
    }
  }

  // اعتماد مستخدم (تغيير is_approved إلى true)
  Future<Response> approveUser(dynamic userId) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/$userId/approve';

    print(" PUT Approve User: $url");
    print(" Headers: $headers");

    try {
      return await dio.put(
        url,
        data: {"is_approved": true},
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      print(" DioError [Approve User]: ${e.message}");
      rethrow;
    }
  }

  // تغيير كلمة المرور للمستخدم
  Future<Response> changeUserPassword(
    dynamic userId,
    String newPassword,
    String confirmPassword,
  ) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/$userId/change-password';

    print(" PUT Change Password: $url");
    print(" Headers: $headers");

    try {
      return await dio.put(
        url,
        data: {
          "new_password": newPassword,
          "confirm_password": confirmPassword,
        },
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      print(" DioError [Change Password]: ${e.message}");
      rethrow;
    }
  }

  // رفض مستخدم (حذف المستخدم)
  Future<Response> rejectUser(dynamic userId) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/$userId';

    print(" DELETE Reject User: $url");
    print(" Headers: $headers");

    try {
      return await dio.delete(url, options: Options(headers: headers));
    } on DioException catch (e) {
      print(" DioError [Reject User]: ${e.message}");
      rethrow;
    }
  }

  // إنشاء مستخدم أدمن جديد
  Future<Response> createAdminUser({
    required String name,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String address,
    String? notes,
    dynamic image,
  }) async {
    final headers = await _getHeaders();

    // إعداد البيانات
    Map<String, dynamic> data = {
      'name': name,
      'phone': phone,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'address': address,
      'is_approved': true, // دايماً true للأدمن
      'role': 0, // دايماً 0 للأدمن
      'notes': notes ?? '00',
    };

    // إضافة الصورة إذا كانت موجودة
    if (image != null) {
      data['avatar'] = image;
    }

    print(" POST Create Admin User: $baseUrl");
    print(" Headers: $headers");
    print("📦 Data: $data");

    try {
      return await dio.post(
        baseUrl,
        data: data,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      print(" DioError [Create Admin User]: ${e.message}");
      rethrow;
    }
  }

  // تحديث نسبة العمولة للمستخدم
  Future<Response> changeUserCommission(dynamic userId, double commissionPercentage) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/$userId/change-commission';

    print(" PUT Change Commission: $url");
    print(" Data: {commission_percentage: $commissionPercentage}");
    print(" Headers: $headers");

    try {
      return await dio.put(
        url,
        data: {"commission_percentage": commissionPercentage},
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      print(" DioError [Change Commission]: ${e.message}");
      rethrow;
    }
  }

  // تحديث حالة النشاط للمستخدم
  Future<Response> changeUserActiveStatus(dynamic userId, bool isActive) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/$userId/change-active-status';

    print(" PUT Change Active Status: $url");
    print(" Data: {is_active: $isActive}");
    print(" Headers: $headers");

    try {
      return await dio.put(
        url,
        data: {"is_active": isActive},
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      print(" DioError [Change Active Status]: ${e.message}");
      rethrow;
    }
  }

  // تبديل حالة التوفر للمستخدم الحالي
  Future<Response> toggleMyAvailability(bool currentAvailability) async {
    final headers = await _getHeaders();
    const url = 'http://127.0.0.1:8000/api/v1/dashboard/users/toggle-my-availability';

    // تبديل الحالة: إذا كان متاح يصبح غير متاح والعكس
    final newAvailability = !currentAvailability;

    final data = {
      "is_available": newAvailability,
    };

    print("🔄 PUT Toggle My Availability: $url");
    print("📤 Headers: $headers");
    print("📦 Data: $data");

    try {
      return await dio.put(
        url,
        data: data,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      print("❌ DioError [Toggle My Availability]: ${e.message}");
      print("❌ Status Code: ${e.response?.statusCode}");
      print("❌ Response Data: ${e.response?.data}");
      rethrow;
    }
  }

  // تسجيل الخروج
  Future<Response> logout() async {
    final headers = await _getHeaders();
    const url = 'http://127.0.0.1:8000/api/v1/logout';



    // Try different HTTP methods to handle 405 error
    final methods = ['POST', 'DELETE', 'PUT'];
    
    for (String method in methods) {
      try {
        
        Response response;
        switch (method) {
          case 'POST':
            response = await dio.post(url, options: Options(headers: headers));
            break;
          case 'DELETE':
            response = await dio.delete(url, options: Options(headers: headers));
            break;
          case 'PUT':
            response = await dio.put(url, options: Options(headers: headers));
            break;
          default:
            continue;
        }
        
        print("✅ $method method succeeded with status: ${response.statusCode}");
        return response;
        
      } on DioException catch (e) {
        print("❌ $method method failed: ${e.response?.statusCode} - ${e.message}");
        if (method == methods.last) {
          // If all methods fail, rethrow the last error
          rethrow;
        }
        continue;
      }
    }
    
    throw Exception('All logout methods failed');
  }

  // الحصول على headers مع التوكن
  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}
