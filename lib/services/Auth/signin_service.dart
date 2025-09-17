//lib/features/auth/data/services/signin_service.dart

import '../api_service.dart';
class SigninService extends ApiService {
  SigninService() : super(baseUrl: 'http://127.0.0.1:8000/api/v1/login');
}