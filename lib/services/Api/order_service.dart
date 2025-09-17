import 'package:dio/dio.dart';
import '../api_service.dart';
import '../Auth/token_storage.dart';

class OrderService extends ApiService {
  OrderService() : super(baseUrl: 'http://127.0.0.1:8000/api/v1/dashboard/orders');

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
  Future<Response> updateOrder(dynamic orderId, Map<String, dynamic> data) async {
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
        queryParameters: {
          'status': 2,
          'user_add_id': deliveryId,
        },
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      print("❌ DioError [GET ORDERS FOR DELIVERY]: ${e.message}");
      rethrow;
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