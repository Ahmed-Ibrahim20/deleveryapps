import '../api_service.dart';

class UserService extends ApiService {
  UserService() : super(baseUrl: 'http://127.0.0.1:8000/api/v1/users');
}