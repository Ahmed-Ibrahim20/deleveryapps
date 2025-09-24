import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  PusherChannelsFlutter? _pusher;
  PusherChannel? _driversChannel;
  PusherChannel? _shopChannel;
  PusherChannel? _adminChannel;
  NotificationProvider? _notificationProvider;
  bool _isConnected = false;

  // Pusher configuration
  static const String _key = 'your-pusher-key';
  static const String _cluster = 'your-pusher-cluster';

  bool get isConnected => _isConnected;

  /// تهيئة WebSocket connection
  Future<void> initialize(NotificationProvider notificationProvider) async {
    _notificationProvider = notificationProvider;
    
    try {
      _pusher = PusherChannelsFlutter.getInstance();
      
      await _pusher!.init(
        apiKey: _key,
        cluster: _cluster,
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onEvent: _onEvent,
        onSubscriptionError: _onSubscriptionError,
        onDecryptionFailure: _onDecryptionFailure,
        onMemberAdded: _onMemberAdded,
        onMemberRemoved: _onMemberRemoved,
      );

      await _pusher!.connect();
      print('🔌 WebSocket connection initialized');
      
    } catch (e) {
      print('❌ Error initializing WebSocket: $e');
    }
  }

  /// الاشتراك في القنوات حسب دور المستخدم
  Future<void> subscribeToChannels() async {
    if (_pusher == null || _notificationProvider == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 0;
      final role = prefs.getInt('role') ?? 1;
      final userRole = UserRole.fromInt(role);

      switch (userRole) {
        case UserRole.admin:
          await _subscribeToAdminChannel();
          break;
        case UserRole.driver:
          await _subscribeToDriversChannel();
          break;
        case UserRole.shop:
          await _subscribeToShopChannel(userId);
          break;
      }
      
      print('✅ Subscribed to channels for role: ${userRole.name}');
      
    } catch (e) {
      print('❌ Error subscribing to channels: $e');
    }
  }

  /// الاشتراك في قناة الأدمن
  Future<void> _subscribeToAdminChannel() async {
    try {
      _adminChannel = await _pusher!.subscribe(channelName: 'admin-notifications');
      print('✅ Subscribed to admin channel');
      
    } catch (e) {
      print('❌ Error subscribing to admin channel: $e');
    }
  }

  /// الاشتراك في قناة السائقين
  Future<void> _subscribeToDriversChannel() async {
    try {
      _driversChannel = await _pusher!.subscribe(channelName: 'driver-notifications');
      print('✅ Subscribed to drivers channel');
      
    } catch (e) {
      print('❌ Error subscribing to drivers channel: $e');
    }
  }

  /// الاشتراك في قناة المتجر
  Future<void> _subscribeToShopChannel(int userId) async {
    try {
      _shopChannel = await _pusher!.subscribe(channelName: 'shop-notifications.$userId');
      print('✅ Subscribed to shop channel for user: $userId');
      
    } catch (e) {
      print('❌ Error subscribing to shop channel: $e');
    }
  }

  /// معالجة الأحداث الواردة من WebSocket
  /// يتم استدعاؤها عند وصول إشعارات من الخادم
  void _handleWebSocketEvent(String eventType, dynamic data) {
    try {
      NotificationModel? notification;
      
      switch (eventType) {
        case 'user_registered':
          notification = NotificationModel(
            id: data['notification_id'] ?? 0,
            title: 'طلب فتح حساب جديد',
            message: data['message'] ?? 'مستخدم جديد في انتظار الموافقة',
            type: 'user_registered',
            notifiableType: 'App\\Models\\User',
            notifiableId: data['user_id'] ?? 0,
            isRead: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            data: data,
          );
          break;
          
        case 'order_created':
          notification = NotificationModel(
            id: data['notification_id'] ?? 0,
            title: 'طلب جديد متاح',
            message: data['message'] ?? 'يوجد طلب جديد متاح للتوصيل',
            type: 'order_created',
            notifiableType: 'App\\Models\\Order',
            notifiableId: data['order_id'] ?? 0,
            isRead: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            data: data,
          );
          break;
          
        case 'order_accepted':
          notification = NotificationModel(
            id: data['notification_id'] ?? 0,
            title: 'تم قبول الطلب',
            message: data['message'] ?? 'تم قبول طلبك من قبل السائق',
            type: 'order_accepted',
            notifiableType: 'App\\Models\\Order',
            notifiableId: data['order_id'] ?? 0,
            isRead: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            data: data,
          );
          break;
          
        case 'order_delivered':
          notification = NotificationModel(
            id: data['notification_id'] ?? 0,
            title: 'تم تسليم الطلب',
            message: data['message'] ?? 'تم تسليم طلبك بنجاح',
            type: 'order_delivered',
            notifiableType: 'App\\Models\\Order',
            notifiableId: data['order_id'] ?? 0,
            isRead: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            data: data,
          );
          break;
          
        case 'order_cancelled':
          notification = NotificationModel(
            id: data['notification_id'] ?? 0,
            title: 'تم إلغاء الطلب',
            message: data['message'] ?? 'تم إلغاء طلبك',
            type: 'order_cancelled',
            notifiableType: 'App\\Models\\Order',
            notifiableId: data['order_id'] ?? 0,
            isRead: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            data: data,
          );
          break;
      }
      
      if (notification != null) {
        _notificationProvider?.addNewNotification(notification);
        _showOverlayNotification(notification);
        print('📢 WebSocket notification received: $eventType');
      }
      
    } catch (e) {
      print('❌ Error handling WebSocket event: $e');
    }
  }

  /// عرض إشعار خارجي على الشاشة
  void _showOverlayNotification(NotificationModel notification) {
    // TODO: تطبيق عرض الإشعارات الخارجية
    print('🔔 Showing overlay notification: ${notification.title}');
  }

  /// معالجة تغيير حالة الاتصال
  void _onConnectionStateChange(dynamic currentState, dynamic previousState) {
    _isConnected = currentState == 'connected';
    print('🔌 Connection state changed: $previousState -> $currentState');
  }

  /// معالجة الأخطاء
  void _onError(String message, int? code, dynamic e) {
    print('❌ WebSocket error: $message (Code: $code)');
  }

  /// معالجة نجاح الاشتراك
  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    print('✅ Successfully subscribed to: $channelName');
  }

  /// معالجة الأحداث العامة
  void _onEvent(PusherEvent event) {
    print('📡 Received event: ${event.eventName} on ${event.channelName}');
  }

  /// معالجة خطأ الاشتراك
  void _onSubscriptionError(String message, dynamic e) {
    print('❌ Subscription error: $message');
  }

  /// معالجة فشل فك التشفير
  void _onDecryptionFailure(String event, String reason) {
    print('❌ Decryption failure: $event - $reason');
  }

  /// معالجة إضافة عضو
  void _onMemberAdded(String channelName, PusherMember member) {
    print('👤 Member added to $channelName: ${member.userId}');
  }

  /// معالجة إزالة عضو
  void _onMemberRemoved(String channelName, PusherMember member) {
    print('👤 Member removed from $channelName: ${member.userId}');
  }

  /// قطع الاتصال
  Future<void> disconnect() async {
    try {
      await _driversChannel?.unsubscribe();
      await _shopChannel?.unsubscribe();
      await _adminChannel?.unsubscribe();
      await _pusher?.disconnect();
      
      _driversChannel = null;
      _shopChannel = null;
      _adminChannel = null;
      _isConnected = false;
      
      print('🔌 WebSocket disconnected');
      
    } catch (e) {
      print('❌ Error disconnecting WebSocket: $e');
    }
  }

  /// إعادة الاتصال
  Future<void> reconnect() async {
    await disconnect();
    if (_notificationProvider != null) {
      await initialize(_notificationProvider!);
      await subscribeToChannels();
    }
  }
}
