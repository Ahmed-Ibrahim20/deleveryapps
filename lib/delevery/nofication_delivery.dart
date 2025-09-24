import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../services/overlay_notification_service.dart';
import 'order_screen.dart';

class NotificationDelivery extends StatefulWidget {
  final String phone;

  const NotificationDelivery({super.key, required this.phone});

  @override
  State<NotificationDelivery> createState() => _NotificationDeliveryState();
}

class _NotificationDeliveryState extends State<NotificationDelivery> {
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
          provider.updateUserRole(UserRole.driver);
          provider.fetchNotifications(forceRefresh: true);
          print('🚚 Driver notifications page initialized - Loading notifications...');
        } catch (e) {
          print('❌ Error initializing driver notifications page: $e');
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
            'إشعارات السائق',
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
                  child: const Icon(Icons.delivery_dining, color: Colors.white),
                );
              }
              return const Icon(Icons.delivery_dining, color: Colors.white);
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
            const PopupMenuItem(
              value: 'view_orders',
              child: Row(
                children: [
                  Icon(Icons.list_alt, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('عرض الطلبات'),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delivery_dining_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'لا توجد طلبات جديدة',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'سيتم إشعارك عند توفر طلبات جديدة',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateToOrders(),
              icon: const Icon(Icons.list_alt),
              label: const Text('عرض جميع الطلبات'),
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
            color: notification.isRead ? Colors.grey.shade300 : Colors.orange.shade300,
            width: notification.isRead ? 0.5 : 1.5,
          ),
        ),
        color: notification.isRead ? Colors.white : Colors.orange.shade50,
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
                      color: Colors.orange,
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
                      Row(
                        children: [
                          Text(
                            notification.timeAgo,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          if (notification.type == 'order_created')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'طلب جديد',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
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
    // إزالة جميع الأزرار - سيتم التعامل مع الإشعارات عبر الضغط عليها مباشرة
    return const SizedBox.shrink();
  }

  Widget _buildFloatingActionButton() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.unreadCount == 0) return const SizedBox.shrink();
        
        return FloatingActionButton.extended(
          onPressed: () => _markAllAsRead(provider),
          backgroundColor: Colors.orange,
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
      case 'view_orders':
        _navigateToOrders();
        break;
    }
  }

  /// معالجة النقر على الإشعار
  void _handleNotificationTap(NotificationModel notification, NotificationProvider provider) {
    // تحديد الإشعار كمقروء
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    // التنقل مباشرة لصفحة الطلبات بدون modal
    _navigateToOrders();
  }

  /// فحص ما إذا كان الإشعار يحتوي على إجراءات
  bool _hasActions(String type) {
    return false; // إزالة جميع الإجراءات المباشرة
  }


  /// التنقل لصفحة الطلبات
  void _navigateToOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderScreenDesign(phone: widget.phone),
      ),
    );
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
      default:
        return Icons.notifications;
    }
  }

  /// الحصول على لون الإشعار
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order_created':
        return Colors.orange;
      case 'order_accepted':
        return Colors.green;
      case 'order_delivered':
        return Colors.blue;
      case 'order_cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
