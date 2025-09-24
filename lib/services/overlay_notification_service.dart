import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart' hide NotificationResponse;

class OverlayNotificationService {
  static final OverlayNotificationService _instance = OverlayNotificationService._internal();
  factory OverlayNotificationService() => _instance;
  OverlayNotificationService._internal();

  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;

  /// تهيئة خدمة الإشعارات
  Future<void> initialize() async {
    if (_isInitialized) return;

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // إعدادات Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // إعدادات iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin?.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    print('✅ Overlay notification service initialized');
  }

  /// معالجة النقر على الإشعار
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    // يمكن إضافة منطق التنقل هنا
  }

  /// عرض إشعار خارجي على الشاشة
  void showOverlayNotification(NotificationModel notification) {
    showOverlay(
      (context, t) => _buildOverlayNotification(notification, context),
      duration: const Duration(seconds: 4),
    );

    // عرض إشعار محلي أيضاً
    _showLocalNotification(notification);
  }

  /// بناء widget الإشعار الخارجي
  Widget _buildOverlayNotification(NotificationModel notification, BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _getNotificationBorderColor(notification.type),
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () {
            // إغلاق الإشعار تلقائياً
            Navigator.of(context).pop();
            // يمكن إضافة منطق التنقل هنا
            _handleNotificationTap(notification);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // أيقونة الإشعار
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // محتوى الإشعار
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.timeAgo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // زر الإغلاق
                IconButton(
                  onPressed: () {
                    // إغلاق الإشعار
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.grey,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// عرض إشعار محلي
  Future<void> _showLocalNotification(NotificationModel notification) async {
    if (_flutterLocalNotificationsPlugin == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'delivery_app_channel',
      'Delivery App Notifications',
      channelDescription: 'Notifications for delivery app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin?.show(
      notification.id,
      notification.title,
      notification.message,
      platformChannelSpecifics,
      payload: notification.id.toString(),
    );
  }

  /// معالجة النقر على الإشعار الخارجي
  void _handleNotificationTap(NotificationModel notification) {
    print('🔔 Overlay notification tapped: ${notification.title}');
    
    // يمكن إضافة منطق التنقل حسب نوع الإشعار
    switch (notification.type) {
      case 'order_created':
        // التنقل لصفحة الطلبات للسائقين
        break;
      case 'order_accepted':
      case 'order_delivered':
      case 'order_cancelled':
        // التنقل لصفحة تفاصيل الطلب للمتاجر
        break;
      case 'user_registered':
      case 'complaint':
      case 'support_message':
        // التنقل لصفحة الإدارة للأدمن
        break;
    }
  }

  /// الحصول على أيقونة الإشعار
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order_created':
        return Icons.delivery_dining;
      case 'order_accepted':
        return Icons.check_circle;
      case 'order_delivered':
        return Icons.done_all;
      case 'order_cancelled':
        return Icons.cancel;
      case 'user_registered':
        return Icons.person_add;
      case 'complaint':
        return Icons.report_problem;
      case 'support_message':
        return Icons.support_agent;
      default:
        return Icons.notifications;
    }
  }

  /// الحصول على لون الإشعار
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order_created':
        return Colors.blue;
      case 'order_accepted':
        return Colors.green;
      case 'order_delivered':
        return Colors.teal;
      case 'order_cancelled':
        return Colors.red;
      case 'user_registered':
        return Colors.purple;
      case 'complaint':
        return Colors.orange;
      case 'support_message':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  /// الحصول على لون حدود الإشعار
  Color _getNotificationBorderColor(String type) {
    switch (type) {
      case 'order_created':
        return Colors.blue.shade300;
      case 'order_accepted':
        return Colors.green.shade300;
      case 'order_delivered':
        return Colors.teal.shade300;
      case 'order_cancelled':
        return Colors.red.shade300;
      case 'user_registered':
        return Colors.purple.shade300;
      case 'complaint':
        return Colors.orange.shade300;
      case 'support_message':
        return Colors.indigo.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  /// عرض إشعار نجاح
  void showSuccessNotification(String title, String message) {
    showSimpleNotification(
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      background: Colors.green,
      duration: const Duration(seconds: 3),
      position: NotificationPosition.top,
    );
  }

  /// عرض إشعار خطأ
  void showErrorNotification(String title, String message) {
    showSimpleNotification(
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      background: Colors.red,
      duration: const Duration(seconds: 4),
      position: NotificationPosition.top,
    );
  }

  /// عرض إشعار تحذير
  void showWarningNotification(String title, String message) {
    showSimpleNotification(
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      background: Colors.orange,
      duration: const Duration(seconds: 3),
      position: NotificationPosition.top,
    );
  }

  /// عرض إشعار معلومات
  void showInfoNotification(String title, String message) {
    showSimpleNotification(
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      background: Colors.blue,
      duration: const Duration(seconds: 3),
      position: NotificationPosition.top,
    );
  }
}
