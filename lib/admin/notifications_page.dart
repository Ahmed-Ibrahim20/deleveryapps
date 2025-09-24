import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../services/overlay_notification_service.dart';
import 'PendingUsersPage.dart';
import 'SupportPage.dart';
// import '../delevery/home_delevery.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ScrollController _scrollController = ScrollController();
  final OverlayNotificationService _overlayService = OverlayNotificationService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // تهيئة خدمة الإشعارات الخارجية
    _overlayService.initialize();
    
    // جلب الإشعارات عند بدء الصفحة مع عرض loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final provider = Provider.of<NotificationProvider>(context, listen: false);
          provider.updateUserRole(UserRole.admin);
          // عرض loading أثناء جلب الإشعارات
          provider.fetchNotifications(forceRefresh: true);
          print('🔔 Admin notifications page initialized - Loading notifications...');
        } catch (e) {
          print('❌ Error initializing notifications page: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      if (provider.hasMorePages && !provider.isLoadingMore) {
        provider.loadMoreNotifications();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: () => provider.fetchNotifications(forceRefresh: true),
              child: _buildBody(provider),
            );
          },
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Row(
        children: [
          const Text(
            'إشعارات الأدمن',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount > 0) {
                return badges.Badge(
                  badgeContent: Text(
                    provider.unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  badgeStyle: const badges.BadgeStyle(
                    badgeColor: Colors.red,
                  ),
                  child: const Icon(Icons.notifications, color: Colors.white),
                );
              }
              return const Icon(Icons.notifications, color: Colors.white);
            },
          ),
        ],
      ),
      centerTitle: false,
      elevation: 0,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'mark_all_read',
              child: Row(
                children: [
                  Icon(Icons.done_all, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('تحديد الكل كمقروء'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, color: Colors.green),
                  SizedBox(width: 8),
                  Text('تحديث'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(NotificationProvider provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل الإشعارات...'),
          ],
        ),
      );
    }

    if (provider.error != null && provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'خطأ في تحميل الإشعارات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.fetchNotifications(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (provider.notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا توجد إشعارات',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: provider.notifications.length + (provider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.notifications.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final notification = provider.notifications[index];
        return _buildNotificationCard(notification, provider);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, NotificationProvider provider) {
    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        provider.deleteNotification(notification.id);
        _overlayService.showInfoNotification(
          'تم الحذف',
          'تم حذف الإشعار بنجاح',
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        elevation: notification.isRead ? 1 : 3,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: notification.isRead ? Colors.grey.shade300 : Colors.blue.shade300,
            width: notification.isRead ? 0.5 : 1.5,
          ),
        ),
        color: notification.isRead ? Colors.white : Colors.blue.shade50,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification, provider),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // مؤشر عدم القراءة
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (!notification.isRead) const SizedBox(width: 12),
                
                // أيقونة الإشعار
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // محتوى الإشعار
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
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
                
                // أزرار الإجراءات
                if (_hasActions(notification.type))
                  _buildActionButtons(notification, provider),
                
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(NotificationModel notification, NotificationProvider provider) {
    // إزالة أزرار الصح والغلط - سيتم التعامل مع الإشعارات عبر الضغط عليها
    return const SizedBox.shrink();
  }

  Widget _buildFloatingActionButton() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.unreadCount == 0) return const SizedBox.shrink();
        
        return FloatingActionButton.extended(
          onPressed: () => _markAllAsRead(provider),
          backgroundColor: Colors.blue,
          icon: const Icon(Icons.done_all, color: Colors.white),
          label: Text(
            'تحديد الكل كمقروء (${provider.unreadCount})',
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  /// معالجة إجراءات القائمة
  void _handleMenuAction(String action) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    
    switch (action) {
      case 'mark_all_read':
        _markAllAsRead(provider);
        break;
      case 'refresh':
        provider.fetchNotifications(forceRefresh: true);
        break;
    }
  }

  /// معالجة النقر على الإشعار
  void _handleNotificationTap(NotificationModel notification, NotificationProvider provider) {
    // تحديد الإشعار كمقروء
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    // التنقل حسب نوع الإشعار
    switch (notification.type) {
      case 'user_registered':
        // الانتقال لصفحة طلبات فتح الحساب
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PendingUsersPage(),
          ),
        );
        break;
      case 'complaint':
      case 'support_message':
        // الانتقال لصفحة الدعم الفني والشكاوي
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SupportPage(),
          ),
        );
        break;
      default:
        // عرض تفاصيل الإشعار
        _showNotificationDetails(notification);
        break;
    }
  }

  /// فحص ما إذا كان الإشعار يحتوي على إجراءات
  bool _hasActions(String type) {
    return false; // إزالة جميع الإجراءات المباشرة
  }


  /// تحديد جميع الإشعارات كمقروءة
  Future<void> _markAllAsRead(NotificationProvider provider) async {
    try {
      final success = await provider.markAllAsRead();
      
      if (success) {
        _overlayService.showSuccessNotification(
          'تم التحديث',
          'تم تحديد جميع الإشعارات كمقروءة',
        );
      } else {
        _overlayService.showErrorNotification(
          'خطأ',
          'فشل في تحديد الإشعارات كمقروءة',
        );
      }
    } catch (e) {
      _overlayService.showErrorNotification(
        'خطأ',
        'حدث خطأ أثناء التحديث: $e',
      );
    }
  }


  /// عرض تفاصيل الإشعار
  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(notification.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              const SizedBox(height: 16),
              Text(
                'الوقت: ${notification.timeAgo}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (notification.data != null) ...[
                const SizedBox(height: 16),
                const Text('تفاصيل إضافية:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(notification.data.toString()),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  /// الحصول على أيقونة الإشعار
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'user_registered':
        return Icons.person_add;
      case 'complaint':
        return Icons.report_problem;
      case 'support_message':
        return Icons.support_agent;
      case 'order_created':
        return Icons.delivery_dining;
      case 'order_accepted':
        return Icons.check_circle;
      case 'order_delivered':
        return Icons.done_all;
      case 'order_cancelled':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  /// الحصول على لون الإشعار
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'user_registered':
        return Colors.blue;
      case 'complaint':
        return Colors.orange;
      case 'support_message':
        return Colors.indigo;
      case 'order_created':
        return Colors.green;
      case 'order_accepted':
        return Colors.teal;
      case 'order_delivered':
        return Colors.purple;
      case 'order_cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
