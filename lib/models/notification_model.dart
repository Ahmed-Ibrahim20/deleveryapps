class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final String notifiableType;
  final int notifiableId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.notifiableType,
    required this.notifiableId,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      notifiableType: json['notifiable_type'] ?? '',
      notifiableId: json['notifiable_id'] ?? 0,
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
    );
  }

  /// Factory constructor للتعامل مع هيكل API الجديد
  factory NotificationModel.fromApiJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: _determineTypeFromTitle(json['title'] ?? ''),
      notifiableType: json['notifiable_type'] ?? '',
      notifiableId: json['notifiable_id'] ?? 0,
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      data: json['notifiable'] != null ? Map<String, dynamic>.from(json['notifiable']) : null,
    );
  }

  /// تحديد نوع الإشعار من العنوان
  static String _determineTypeFromTitle(String title) {
    if (title.contains('تسجيل مستخدم') || title.contains('مستخدم جديد')) {
      return 'user_registered';
    } else if (title.contains('طلب جديد')) {
      return 'order_created';
    } else if (title.contains('قبول الطلب')) {
      return 'order_accepted';
    } else if (title.contains('تسليم الطلب')) {
      return 'order_delivered';
    } else if (title.contains('إلغاء الطلب')) {
      return 'order_cancelled';
    } else if (title.contains('شكوى')) {
      return 'complaint';
    } else {
      return 'general';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'notifiable_type': notifiableType,
      'notifiable_id': notifiableId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'data': data,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    String? notifiableType,
    int? notifiableId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      notifiableType: notifiableType ?? this.notifiableType,
      notifiableId: notifiableId ?? this.notifiableId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      data: data ?? this.data,
    );
  }

  // Helper methods لتحديد نوع الإشعار
  bool get isOrderNotification => type.contains('order');
  bool get isUserNotification => type.contains('user');
  bool get isComplaintNotification => type.contains('complaint');
  
  // Helper method للحصول على الوقت المنسق
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'منذ لحظات';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return 'منذ ${(difference.inDays / 7).floor()} أسبوع';
    }
  }
}

class NotificationStats {
  final int totalCount;
  final int unreadCount;
  final int readCount;
  final Map<String, int> typeBreakdown;

  NotificationStats({
    required this.totalCount,
    required this.unreadCount,
    required this.readCount,
    required this.typeBreakdown,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      totalCount: json['total_count'] ?? 0,
      unreadCount: json['unread_count'] ?? 0,
      readCount: json['read_count'] ?? 0,
      typeBreakdown: Map<String, int>.from(json['type_breakdown'] ?? {}),
    );
  }
}

class NotificationResponse {
  final List<NotificationModel> notifications;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMorePages;
  final int unreadCount;

  NotificationResponse({
    required this.notifications,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.hasMorePages,
    required this.unreadCount,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? [];
    final notifications = (data as List)
        .map((item) => NotificationModel.fromJson(item))
        .toList();

    return NotificationResponse(
      notifications: notifications,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      total: json['total'] ?? 0,
      hasMorePages: json['current_page'] < json['last_page'],
      unreadCount: notifications.where((n) => !n.isRead).length,
    );
  }
}

// Enum لأنواع الإشعارات
enum NotificationType {
  orderCreated('order_created'),
  orderAccepted('order_accepted'),
  orderDelivered('order_delivered'),
  orderCancelled('order_cancelled'),
  userRegistered('user_registered'),
  userApproved('user_approved'),
  userRejected('user_rejected'),
  complaint('complaint'),
  supportMessage('support_message');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.orderCreated,
    );
  }
}

// Enum لأدوار المستخدمين
enum UserRole {
  admin(0),
  driver(1),
  shop(2);

  const UserRole(this.value);
  final int value;

  static UserRole fromInt(int value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.driver,
    );
  }
}
