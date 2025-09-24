import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/Api/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  // State variables
  List<NotificationModel> _notifications = [];
  NotificationStats? _stats;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;
  UserRole? _userRole;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  NotificationStats? get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  int get unreadCount => _stats?.unreadCount ?? 0;
  bool get hasMorePages => _hasMorePages;
  UserRole? get userRole => _userRole;

  // Filtered notifications
  List<NotificationModel> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();

  List<NotificationModel> get readNotifications => 
      _notifications.where((n) => n.isRead).toList();

  NotificationProvider() {
    _initializeUserRole();
  }

  /// تهيئة دور المستخدم من SharedPreferences
  Future<void> _initializeUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roleValue = prefs.getInt('role') ?? 1;
      _userRole = UserRole.fromInt(roleValue);
      notifyListeners();
    } catch (e) {
      print('❌ Error initializing user role: $e');
    }
  }

  /// جلب الإشعارات (الصفحة الأولى)
  Future<void> fetchNotifications({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    if (forceRefresh) {
      _currentPage = 1;
      _hasMorePages = true;
    }
    notifyListeners();

    try {
      NotificationResponse response;
      
      if (_userRole != null) {
        response = await _notificationService.getNotificationsByRole(
          _userRole!,
          page: _currentPage,
        );
      } else {
        response = await _notificationService.getNotifications(
          page: _currentPage,
        );
      }

      if (forceRefresh || _currentPage == 1) {
        _notifications = response.notifications;
      } else {
        _notifications.addAll(response.notifications);
      }

      _currentPage = response.currentPage;
      _hasMorePages = response.hasMorePages;

      // جلب الإحصائيات
      await _fetchStats();

    } catch (e) {
      _error = e.toString();
      print('❌ Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// جلب المزيد من الإشعارات (pagination)
  Future<void> loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMorePages) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      NotificationResponse response;
      
      if (_userRole != null) {
        response = await _notificationService.getNotificationsByRole(
          _userRole!,
          page: _currentPage + 1,
        );
      } else {
        response = await _notificationService.getNotifications(
          page: _currentPage + 1,
        );
      }

      _notifications.addAll(response.notifications);
      _currentPage = response.currentPage;
      _hasMorePages = response.hasMorePages;

    } catch (e) {
      _error = e.toString();
      print('❌ Error loading more notifications: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// جلب الإحصائيات
  Future<void> _fetchStats() async {
    try {
      _stats = await _notificationService.getNotificationStats();
    } catch (e) {
      print('❌ Error fetching stats: $e');
    }
  }

  /// تحديد إشعار كمقروء
  Future<bool> markAsRead(int notificationId) async {
    try {
      final success = await _notificationService.markAsRead(notificationId);
      
      if (success) {
        // تحديث الإشعار محلياً
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          
          // تحديث الإحصائيات محلياً
          if (_stats != null) {
            _stats = NotificationStats(
              totalCount: _stats!.totalCount,
              unreadCount: _stats!.unreadCount - 1,
              readCount: _stats!.readCount + 1,
              typeBreakdown: _stats!.typeBreakdown,
            );
          }
          
          notifyListeners();
        }
      }
      
      return success;
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// تحديد جميع الإشعارات كمقروءة
  Future<bool> markAllAsRead() async {
    try {
      final success = await _notificationService.markAllAsRead();
      
      if (success) {
        // تحديث جميع الإشعارات محلياً
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        
        // تحديث الإحصائيات محلياً
        if (_stats != null) {
          _stats = NotificationStats(
            totalCount: _stats!.totalCount,
            unreadCount: 0,
            readCount: _stats!.totalCount,
            typeBreakdown: _stats!.typeBreakdown,
          );
        }
        
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      return false;
    }
  }

  /// حذف إشعار
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final success = await _notificationService.deleteNotification(notificationId);
      
      if (success) {
        // حذف الإشعار محلياً
        final notification = _notifications.firstWhere((n) => n.id == notificationId);
        _notifications.removeWhere((n) => n.id == notificationId);
        
        // تحديث الإحصائيات محلياً
        if (_stats != null) {
          _stats = NotificationStats(
            totalCount: _stats!.totalCount - 1,
            unreadCount: notification.isRead ? _stats!.unreadCount : _stats!.unreadCount - 1,
            readCount: notification.isRead ? _stats!.readCount - 1 : _stats!.readCount,
            typeBreakdown: _stats!.typeBreakdown,
          );
        }
        
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      print('❌ Error deleting notification: $e');
      return false;
    }
  }

  /// إضافة إشعار جديد (من WebSocket)
  void addNewNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    
    // تحديث الإحصائيات محلياً
    if (_stats != null) {
      _stats = NotificationStats(
        totalCount: _stats!.totalCount + 1,
        unreadCount: _stats!.unreadCount + 1,
        readCount: _stats!.readCount,
        typeBreakdown: _stats!.typeBreakdown,
      );
    }
    
    notifyListeners();
  }

  /// قبول طلب فتح حساب (للأدمن)
  Future<bool> approveUserAccount(int userId) async {
    try {
      return await _notificationService.approveUserAccount(userId);
    } catch (e) {
      print('❌ Error approving user account: $e');
      return false;
    }
  }

  /// رفض طلب فتح حساب (للأدمن)
  Future<bool> rejectUserAccount(int userId, String reason) async {
    try {
      return await _notificationService.rejectUserAccount(userId, reason);
    } catch (e) {
      print('❌ Error rejecting user account: $e');
      return false;
    }
  }

  /// قبول طلب (للسائقين)
  Future<bool> acceptOrder(int orderId) async {
    try {
      return await _notificationService.acceptOrder(orderId);
    } catch (e) {
      print('❌ Error accepting order: $e');
      return false;
    }
  }

  /// جلب تفاصيل الطلب
  Future<Map<String, dynamic>?> getOrderDetails(int orderId) async {
    try {
      return await _notificationService.getOrderDetails(orderId);
    } catch (e) {
      print('❌ Error fetching order details: $e');
      return null;
    }
  }

  /// جلب تفاصيل المستخدم
  Future<Map<String, dynamic>?> getUserDetails(int userId) async {
    try {
      return await _notificationService.getUserDetails(userId);
    } catch (e) {
      print('❌ Error fetching user details: $e');
      return null;
    }
  }

  /// إرسال رد على الشكوى
  Future<bool> replyToComplaint(int complaintId, String reply) async {
    try {
      return await _notificationService.replyToComplaint(complaintId, reply);
    } catch (e) {
      print('❌ Error replying to complaint: $e');
      return false;
    }
  }

  /// تحديث دور المستخدم
  void updateUserRole(UserRole role) {
    _userRole = role;
    notifyListeners();
    // إعادة جلب الإشعارات بناءً على الدور الجديد
    fetchNotifications(forceRefresh: true);
  }

  /// مسح الأخطاء
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// إعادة تعيين البيانات
  void reset() {
    _notifications.clear();
    _stats = null;
    _error = null;
    _currentPage = 1;
    _hasMorePages = true;
    notifyListeners();
  }
}
