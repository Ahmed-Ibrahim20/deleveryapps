import '../api_service.dart';
import 'package:dio/dio.dart';
import 'package:my_app_delevery1/services/Auth/token_storage.dart';

class AuthService extends ApiService {
  AuthService()
    : super(baseUrl: 'http://127.0.0.1:8000/api/v1');

  // إعادة تعيين كلمة المرور
  Future<Response> resetPassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/reset-password';

    print("🔄 POST Reset Password: $url");
    print("🔑 Headers: $headers");

    try {
      return await dio.post(
        url,
        data: {
          "old_password": oldPassword,
          "new_password": newPassword,
          "confirm_password": confirmPassword,
        },
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      print("❌ DioError [Reset Password]: ${e.message}");
      rethrow;
    }
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
