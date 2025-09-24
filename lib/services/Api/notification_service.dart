import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/notification_model.dart';

class NotificationService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1/dashboard';
  final Dio _dio = Dio();

  NotificationService() {
    _initializeService();
    _setupDio();
  }

  /// تهيئة الخدمة والتحقق من التوكن
  Future<void> _initializeService() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getInt('user_id');
    final role = prefs.getInt('role');
    
    print('🔍 Service Initialization:');
    print('   Token: ${token != null ? 'Found (${token.length} chars)' : 'Not found'}');
    print('   User ID: $userId');
    print('   Role: $role');
  }

  void _setupDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.sendTimeout = const Duration(seconds: 15);
    
    // إضافة interceptor للـ Authorization header
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print('🔑 Token added to request: Bearer ${token.substring(0, 10)}...');
        } else {
          print('❌ No token found in SharedPreferences');
        }
        
        options.headers['Accept'] = 'application/json';
        options.headers['Content-Type'] = 'application/json';
        
        print('📤 API Request: ${options.method} ${options.uri}');
        print('📤 Headers: ${options.headers}');
        
        handler.next(options);
      },
      onError: (error, handler) {
        print('❌ Notification API Error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  /// التحقق من وجود التوكن
  Future<bool> _hasValidToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  /// جلب الإشعارات مع pagination
  Future<NotificationResponse> getNotifications({
    int page = 1,
    int perPage = 15,
    bool unreadOnly = false,
    String? type,
  }) async {
    // التحقق من وجود التوكن قبل إرسال الطلب
    if (!await _hasValidToken()) {
      throw Exception('لم يتم العثور على رمز التوثيق. يرجى تسجيل الدخول مرة أخرى.');
    }

    try {
      final queryParams = <String, dynamic>{
        'page': page,
      };

      if (unreadOnly) {
        queryParams['unread_only'] = true;
      }

      if (type != null) {
        queryParams['type'] = type;
      }

      final response = await _dio.get('/notifications', queryParameters: queryParams);
      
      if (response.statusCode == 200 && response.data['status'] == true) {
        // تحويل البيانات من الهيكل الجديد
        final data = response.data['data'];
        final notifications = (data['data'] as List)
            .map((item) => NotificationModel.fromApiJson(item))
            .toList();
        
        return NotificationResponse(
          notifications: notifications,
          currentPage: data['current_page'] ?? 1,
          lastPage: data['last_page'] ?? 1,
          total: data['total'] ?? 0,
          hasMorePages: data['next_page_url'] != null,
          unreadCount: notifications.where((n) => !n.isRead).length,
        );
      } else {
        throw Exception('فشل في جلب الإشعارات: ${response.data['message'] ?? 'خطأ غير معروف'}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('خطأ غير متوقع: $e');
    }
  }

  /// جلب الإشعارات غير المقروءة فقط
  Future<NotificationResponse> getUnreadNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    return getNotifications(
      page: page,
      perPage: perPage,
      unreadOnly: true,
    );
  }

  /// جلب إحصائيات الإشعارات
  Future<NotificationStats> getNotificationStats() async {
    try {
      final response = await _dio.get('/notifications/stats');

      if (response.statusCode == 200) {
        return NotificationStats.fromJson(response.data);
      } else {
        throw Exception('فشل في جلب إحصائيات الإشعارات: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching notification stats: $e');
      throw Exception('خطأ في جلب إحصائيات الإشعارات: $e');
    }
  }

  /// تحديد إشعار كمقروء
  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await _dio.put('/notifications/$notificationId/read');

      if (response.statusCode == 200) {
        print('✅ Notification $notificationId marked as read');
        return true;
      } else {
        throw Exception('فشل في تحديد الإشعار كمقروء: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// تحديد جميع الإشعارات كمقروءة
  Future<bool> markAllAsRead() async {
    try {
      final response = await _dio.put('/notifications/mark-all-read');

      if (response.statusCode == 200) {
        print('✅ All notifications marked as read');
        return true;
      } else {
        throw Exception('فشل في تحديد جميع الإشعارات كمقروءة: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      return false;
    }
  }

  /// حذف إشعار
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await _dio.delete('/notifications/$notificationId');

      if (response.statusCode == 200) {
        print('✅ Notification $notificationId deleted');
        return true;
      } else {
        throw Exception('فشل في حذف الإشعار: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting notification: $e');
      return false;
    }
  }

  /// جلب إشعارات حسب النوع (للأدمن، السائقين، المتاجر)
  Future<NotificationResponse> getNotificationsByRole(UserRole role, {
    int page = 1,
    int perPage = 20,
  }) async {
    String? typeFilter;
    
    switch (role) {
      case UserRole.admin:
        // الأدمن يستقبل طلبات فتح الحسابات والشكاوى
        typeFilter = 'user_registered,complaint,support_message';
        break;
      case UserRole.driver:
        // السائقين يستقبلون إشعارات الطلبات الجديدة
        typeFilter = 'order_created';
        break;
      case UserRole.shop:
        // المتاجر تستقبل إشعارات حالة الطلبات
        typeFilter = 'order_accepted,order_delivered,order_cancelled';
        break;
    }

    return getNotifications(
      page: page,
      perPage: perPage,
      type: typeFilter,
    );
  }

  /// قبول طلب فتح حساب (للأدمن)
  Future<bool> approveUserAccount(int userId) async {
    try {
      final response = await _dio.post('/users/$userId/approve');

      if (response.statusCode == 200) {
        print('✅ User account $userId approved');
        return true;
      } else {
        throw Exception('فشل في الموافقة على الحساب: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error approving user account: $e');
      return false;
    }
  }

  /// رفض طلب فتح حساب (للأدمن)
  Future<bool> rejectUserAccount(int userId, String reason) async {
    try {
      final response = await _dio.post('/users/$userId/reject', data: {
        'reason': reason,
      });

      if (response.statusCode == 200) {
        print('✅ User account $userId rejected');
        return true;
      } else {
        throw Exception('فشل في رفض الحساب: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error rejecting user account: $e');
      return false;
    }
  }

  /// قبول طلب (للسائقين)
  Future<bool> acceptOrder(int orderId) async {
    try {
      final response = await _dio.post('/orders/$orderId/accept');

      if (response.statusCode == 200) {
        print('✅ Order $orderId accepted');
        return true;
      } else {
        throw Exception('فشل في قبول الطلب: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error accepting order: $e');
      return false;
    }
  }

  /// جلب تفاصيل الطلب
  Future<Map<String, dynamic>?> getOrderDetails(int orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId');

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('فشل في جلب تفاصيل الطلب: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching order details: $e');
      return null;
    }
  }

  /// جلب تفاصيل المستخدم
  Future<Map<String, dynamic>?> getUserDetails(int userId) async {
    try {
      final response = await _dio.get('/users/$userId');

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('فشل في جلب تفاصيل المستخدم: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching user details: $e');
      return null;
    }
  }

  /// إرسال رد على الشكوى
  Future<bool> replyToComplaint(int complaintId, String reply) async {
    try {
      final response = await _dio.post('/complaints/$complaintId/reply', data: {
        'reply': reply,
      });

      if (response.statusCode == 200) {
        print('✅ Reply sent to complaint $complaintId');
        return true;
      } else {
        throw Exception('فشل في إرسال الرد: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error replying to complaint: $e');
      return false;
    }
  }

  /// معالجة أخطاء Dio
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'انتهت مهلة الاتصال';
      case DioExceptionType.sendTimeout:
        return 'انتهت مهلة الإرسال';
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاستقبال';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return 'خطأ في التوثيق';
        } else if (statusCode == 403) {
          return 'ليس لديك صلاحية للوصول';
        } else if (statusCode == 404) {
          return 'الصفحة غير موجودة';
        } else if (statusCode == 500) {
          return 'خطأ في الخادم';
        } else {
          return 'خطأ في الشبكة: $statusCode';
        }
      case DioExceptionType.cancel:
        return 'تم إلغاء الطلب';
      case DioExceptionType.connectionError:
        return 'خطأ في الاتصال بالإنترنت';
      default:
        return 'خطأ غير متوقع: ${e.message}';
    }
  }
}
