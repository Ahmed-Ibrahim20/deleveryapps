// lib/features/auth/data/services/signup_service.dart

import 'package:dio/dio.dart';
import 'package:my_app_delevery1/services/api_service.dart';

class SignupService extends ApiService {
  SignupService() : super(baseUrl: 'http://127.0.0.1:8000/api/v1/register');

  /// تسجيل مستخدم جديد (سائق أو متجر)
  Future<Response> register(FormData formData) async {
    return await dio.post(
      baseUrl,
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }
}
