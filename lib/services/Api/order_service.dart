import 'package:dio/dio.dart';
import '../api_service.dart';
import '../Auth/token_storage.dart';

class OrderService extends ApiService {
  OrderService()
    : super(baseUrl: 'http://127.0.0.1:8000/api/v1/dashboard/orders');

  // Get all orders
  Future<Response> getAllOrders({int? page}) async {
    return await getAll(page: page);
  }

  // Create new order
  Future<Response> createOrder(Map<String, dynamic> orderData) async {
    return await post(orderData);
  }

  // Get order by ID
  Future<Response> getOrderById(dynamic orderId) async {
    return await getById(orderId);
  }

  // Update order
  Future<Response> updateOrder(
    dynamic orderId,
    Map<String, dynamic> data,
  ) async {
    return await put(orderId, data);
  }

  // Delete order
  Future<Response> deleteOrder(dynamic orderId) async {
    return await delete(orderId);
  }

  // Get user data by phone (for store info)
  Future<Response> getUserByPhone(String phone) async {
    final headers = await _getHeaders();
    final url = 'http://127.0.0.1:8000/api/v1/dashboard/users';

    try {
      final response = await dio.get(
        url,
        queryParameters: {'phone': phone},
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      print("❌ DioError [GET USER BY PHONE]: ${e.message}");
      rethrow;
    }
  }

  // Get orders with status=2 and specific delivery_id
  Future<Response> getOrdersForDelivery(int deliveryId) async {
    final headers = await _getHeaders();

    try {
      final response = await dio.get(
        baseUrl,
        queryParameters: {'status': 2, 'user_add_id': deliveryId},
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      print("❌ DioError [GET ORDERS FOR DELIVERY]: ${e.message}");
      rethrow;
    }
  }
  // Get orders with status=0 (new orders available for delivery) - NEW METHOD
  Future<Response> getNewOrdersForDelivery() async {
    final headers = await _getHeaders();
    
    try {
      final response = await dio.get(
        baseUrl,
        queryParameters: {
          'status': 0, // Only orders with status = 0
        },
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      print("❌ DioError [GET NEW ORDERS FOR DELIVERY]: ${e.message}");
      rethrow;
    }
  }

  // Get orders with status=1 (ongoing orders) - NEW METHOD
  Future<Response> getOngoingOrders() async {
    final headers = await _getHeaders();
    
    try {
      final response = await dio.get(
        baseUrl,
        queryParameters: {
          'status': 1, // Only orders with status = 1
        },
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      print("❌ DioError [GET ONGOING ORDERS]: ${e.message}");
      rethrow;
    }
  }

// Change order status using the new endpoint
  Future<Response> changeOrderStatus(dynamic orderId, int status) async {
    final headers = await _getHeaders();
    final url = '$baseUrl/$orderId/change-status';
    
    try {
      print("🔄 Changing order status - URL: $url");
      print("🔄 Order ID: $orderId, Status: $status");
      print("🔄 Headers: $headers");
      
      // Configure dio with timeout settings
      dio.options.connectTimeout = const Duration(seconds: 15);
      dio.options.receiveTimeout = const Duration(seconds: 15);
      dio.options.sendTimeout = const Duration(seconds: 15);
      
      // Try POST first
      final response = await dio.put(
        url,
        data: {'status': status},
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      print("✅ Status change response: ${response.statusCode}");
      print("✅ Response data: ${response.data}");
      return response;
    } on DioException catch (e) {
      print("❌ POST failed with error type: ${e.type}");
      print("❌ Error message: ${e.message}");
      
      // Handle specific error types
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('انتهت مهلة الاتصال. تحقق من الاتصال بالإنترنت.');
      }
      
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('خطأ في الاتصال بالإنترنت. تحقق من الاتصال وحاول مرة أخرى.');
      }
      
      // If POST fails with 405, try PUT
      if (e.response?.statusCode == 405) {
        try {
          print("🔄 Trying PUT method...");
          final response = await dio.put(
            url,
            data: {'status': status},
            options: Options(
              headers: headers,
              validateStatus: (status) => status != null && status < 500,
            ),
          );
          
          print("✅ Status change response (PUT): ${response.statusCode}");
          print("✅ Response data: ${response.data}");
          return response;
        } on DioException catch (putError) {
          print("❌ PUT also failed: ${putError.message}");
          
          if (putError.type == DioExceptionType.connectionTimeout ||
              putError.type == DioExceptionType.receiveTimeout ||
              putError.type == DioExceptionType.sendTimeout) {
            throw Exception('انتهت مهلة الاتصال. تحقق من الاتصال بالإنترنت.');
          }
          
          if (putError.type == DioExceptionType.connectionError) {
            throw Exception('خطأ في الاتصال بالإنترنت. تحقق من الاتصال وحاول مرة أخرى.');
          }
          
          rethrow;
        }
      }
      
      print("❌ DioError [CHANGE ORDER STATUS]: ${e.message}");
      print("❌ Response: ${e.response?.data}");
      print("❌ Status Code: ${e.response?.statusCode}");
      
      // Provide more specific error messages
      if (e.response?.statusCode == 401) {
        throw Exception('خطأ في التوثيق. قم بتسجيل الدخول مرة أخرى.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('ليس لديك صلاحية لتنفيذ هذا الإجراء.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('الطلب غير موجود أو تم حذفه.');
      } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        throw Exception('خطأ في الخادم. حاول مرة أخرى لاحقاً.');
      }
      
      rethrow;
    } catch (e) {
      print("❌ Unexpected error: $e");
      throw Exception('خطأ غير متوقع. حاول مرة أخرى.');
    }
  }
  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}
