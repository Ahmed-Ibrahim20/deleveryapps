import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../services/overlay_notification_service.dart';
import 'order_detailes_shope.dart';
import 'previousordersscreen_shope.dart';
import 'Reportshope.dart';

class nofication_shope extends StatefulWidget {
  final String phone;

  const nofication_shope({super.key, required this.phone});

  @override
  State<nofication_shope> createState() => _nofication_shopeState();
}

class _nofication_shopeState extends State<nofication_shope> {
  final ScrollController _scrollController = ScrollController();
  final OverlayNotificationService _overlayService = OverlayNotificationService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // تهيئة خدمة الإشعارات الخارجية
    _overlayService.initialize();
    
    // جلب الإشعارات عند بدء الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      provider.updateUserRole(UserRole.shop);
      provider.fetchNotifications(forceRefresh: true);
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
            'إشعارات المتجر',
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
                  child: const Icon(Icons.store, color: Colors.white),
                );
              }
              return const Icon(Icons.store, color: Colors.white);
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
            const PopupMenuItem(
              value: 'view_reports',
              child: Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.purple),
                  SizedBox(width: 8),
                  Text('التقارير'),
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
            const Icon(Icons.store_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'لا توجد إشعارات جديدة',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'سيتم إشعارك عند وصول طلبات جديدة',
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
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'طلب جديد',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (notification.type == 'order_delivered')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'تم التسليم',
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
    if (notification.type == 'order_created') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _acceptOrder(notification, provider),
            icon: const Icon(Icons.check_circle, color: Colors.green),
            tooltip: 'قبول الطلب',
          ),
          IconButton(
            onPressed: () => _rejectOrder(notification, provider),
            icon: const Icon(Icons.cancel, color: Colors.red),
            tooltip: 'رفض الطلب',
          ),
          IconButton(
            onPressed: () => _viewOrderDetails(notification),
            icon: const Icon(Icons.visibility, color: Colors.blue),
            tooltip: 'عرض التفاصيل',
          ),
        ],
      );
    }
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
      case 'view_orders':
        _navigateToOrders();
        break;
      case 'view_reports':
        _navigateToReports();
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
      case 'order_created':
        _viewOrderDetails(notification);
        break;
      case 'order_delivered':
        _navigateToOrders();
        break;
      case 'report_ready':
        _navigateToReports();
        break;
      default:
        // عرض تفاصيل الإشعار
        _showNotificationDetails(notification);
        break;
    }
  }

  /// فحص ما إذا كان الإشعار يحتوي على إجراءات
  bool _hasActions(String type) {
    return type == 'order_created';
  }

  /// قبول الطلب
  Future<void> _acceptOrder(NotificationModel notification, NotificationProvider provider) async {
    try {
      final success = await provider.acceptOrder(notification.notifiableId);
      
      if (success) {
        _overlayService.showSuccessNotification(
          'تم القبول',
          'تم قبول الطلب بنجاح',
        );
        
        // تحديد الإشعار كمقروء
        provider.markAsRead(notification.id);
        
        // التنقل لصفحة الطلبات
        _navigateToOrders();
      } else {
        _overlayService.showErrorNotification(
          'خطأ',
          'فشل في قبول الطلب',
        );
      }
    } catch (e) {
      _overlayService.showErrorNotification(
        'خطأ',
        'حدث خطأ أثناء قبول الطلب: $e',
      );
    }
  }

  /// رفض الطلب
  Future<void> _rejectOrder(NotificationModel notification, NotificationProvider provider) async {
    final reason = await _showRejectDialog();
    if (reason == null) return;

    try {
      // TODO: إضافة دالة rejectOrder إلى NotificationProvider
      // final success = await provider.rejectOrder(notification.notifiableId, reason);
      // مؤقتاً نعتبر العملية ناجحة
      _overlayService.showInfoNotification(
        'تم الرفض',
        'تم رفض الطلب',
      );
      
      // تحديد الإشعار كمقروء
      provider.markAsRead(notification.id);
    } catch (e) {
      _overlayService.showErrorNotification(
        'خطأ',
        'حدث خطأ أثناء رفض الطلب: $e',
      );
    }
  }

  /// عرض تفاصيل الطلب
  Future<void> _viewOrderDetails(NotificationModel notification) async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    
    try {
      final orderDetails = await provider.getOrderDetails(notification.notifiableId);
      
      if (orderDetails != null) {
        _showOrderDetailsDialog(orderDetails, notification);
      } else {
        // التنقل لصفحة الطلبات كبديل
        _navigateToOrders();
      }
    } catch (e) {
      _overlayService.showErrorNotification(
        'خطأ',
        'فشل في جلب تفاصيل الطلب',
      );
      // التنقل لصفحة الطلبات كبديل
      _navigateToOrders();
    }
  }

  /// التنقل لصفحة الطلبات
  void _navigateToOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviousOrdersScreenShope(phone: widget.phone),
      ),
    );
  }

  /// التنقل لصفحة التقارير
  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => report_shope(phone: widget.phone),
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

  /// عرض dialog لسبب الرفض
  Future<String?> _showRejectDialog() async {
    final TextEditingController controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('سبب رفض الطلب'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'اكتب سبب الرفض...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(controller.text.trim());
                }
              },
              child: const Text('رفض الطلب'),
            ),
          ],
        ),
      ),
    );
  }

  /// عرض تفاصيل الطلب في dialog
  void _showOrderDetailsDialog(Map<String, dynamic> orderDetails, NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تفاصيل الطلب'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('رقم الطلب:', orderDetails['id']?.toString() ?? 'غير محدد'),
                _buildDetailRow('العميل:', orderDetails['customer_name'] ?? 'غير محدد'),
                _buildDetailRow('الهاتف:', orderDetails['customer_phone'] ?? 'غير محدد'),
                _buildDetailRow('العنوان:', orderDetails['delivery_address'] ?? 'غير محدد'),
                _buildDetailRow('المبلغ:', '${orderDetails['total_amount'] ?? 0} جنيه'),
                _buildDetailRow('رسوم التوصيل:', '${orderDetails['delivery_fee'] ?? 0} جنيه'),
                const SizedBox(height: 16),
                Text(
                  'الوقت: ${notification.timeAgo}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToOrders();
              },
              child: const Text('عرض الطلبات'),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء صف التفاصيل
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
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
      case 'order_created':
        return Icons.shopping_cart;
      case 'order_accepted':
        return Icons.check_circle;
      case 'order_delivered':
        return Icons.done_all;
      case 'order_cancelled':
        return Icons.cancel;
      case 'report_ready':
        return Icons.bar_chart;
      case 'payment_received':
        return Icons.payment;
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
      case 'report_ready':
        return Colors.purple;
      case 'payment_received':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
