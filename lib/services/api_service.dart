// lib/core/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:my_app_delevery1/services/Auth/token_storage.dart';

class ApiService<T> {
  final String baseUrl;
  final Dio dio;

  ApiService({required this.baseUrl})
      : dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 60), // ⏳ 60 ثانية
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Response> getAll({int? page, String? search}) async {
    final headers = await _getHeaders();
    String url = baseUrl;
    if (page != null) url += "?page=$page";
    if (search != null && search.isNotEmpty) url += "&search=$search";

    print("📡 GET: $url");
    print("🔑 Headers: $headers");

    try {
      return await dio.get(url, options: Options(headers: headers));
    } on DioException catch (e) {
      print("❌ DioError [GET]: ${e.message}");
      rethrow;
    }
  }

  Future<Response> getById(dynamic id) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/$id';

    print("📡 GET: $url");
    print("🔑 Headers: $headers");

    try {
      return await dio.get(url, options: Options(headers: headers));
    } on DioException catch (e) {
      print("❌ DioError [GET BY ID]: ${e.message}");
      rethrow;
    }
  }
Future<Response> post(dynamic data) async {
  final headers = await _getHeaders();

  print("📡 POST: $baseUrl");
  print("🔑 Headers: $headers");
  print("📦 Data: $data");

  try {
    final isAuthEndpoint =
        baseUrl.contains('/login') || baseUrl.contains('/register');

    final response = await dio.post(
      baseUrl,
      data: data,
      options: Options(headers: isAuthEndpoint ? {'Content-Type': 'application/json'} : headers),
    );

    // لو login خزّن التوكن
    if (baseUrl.contains('/login') &&
        response.data != null &&
        response.data['token'] != null) {
      await TokenStorage.saveToken(response.data['token']);
    }

    return response;
  } on DioException catch (e) {
    print("❌ DioError [POST]: ${e.message}");
    rethrow;
  }
}


  Future<Response> put(dynamic id, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/$id';

    print("📡 PUT: $url");
    print("📦 Data: $data");

    try {
      return await dio.put(url, data: data, options: Options(headers: headers));
    } on DioException catch (e) {
      print("❌ DioError [PUT]: ${e.message}");
      rethrow;
    }
  }

  Future<Response> delete(dynamic id) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/$id';

    print("📡 DELETE: $url");

    try {
      return await dio.delete(url, options: Options(headers: headers));
    } on DioException catch (e) {
      print("❌ DioError [DELETE]: ${e.message}");
      rethrow;
    }
  }

  Future<Response> edit(dynamic id) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/edit/$id';

    print("📡 GET (edit): $url");

    try {
      return await dio.get(url, options: Options(headers: headers));
    } on DioException catch (e) {
      print("❌ DioError [EDIT]: ${e.message}");
      rethrow;
    }
  }
}
