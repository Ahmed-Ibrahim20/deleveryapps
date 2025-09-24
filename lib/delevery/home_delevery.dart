import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../store/order_detailes_shope.dart';
import '../store/previousordersscreen_shope.dart';
import '../store/Profileshope.dart';
import './order_screen.dart';
import './ReportDelevery.dart';
import './nofication_delivery.dart';
import '../services/Api/order_service.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

class DriverHomePage extends StatefulWidget {
  final String phone;

  DriverHomePage({Key? key, required this.phone}) : super(key: key);

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  String name = 'مرحباً، مستخدم';
  Map<String, dynamic>? userData;
  int newOrdersCount = 0;
  int currentOrdersCount = 0;
  int completedOrdersCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndCounts();
    
    // تهيئة الإشعارات
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final provider = Provider.of<NotificationProvider>(context, listen: false);
          provider.updateUserRole(UserRole.driver);
          provider.fetchNotifications();
        } catch (e) {
          print('❌ Error initializing NotificationProvider: $e');
        }
      }
    });
  }

  Future<void> _loadUserDataAndCounts() async {
    try {
      // Get user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('name') ?? 'مستخدم';
      final userPhone = prefs.getString('phone') ?? widget.phone;
      final userRole = prefs.getInt('role') ?? 0;
      final userId = prefs.getInt('user_id') ?? 0;
      final userEmail = prefs.getString('email') ?? '';
      final isApproved = prefs.getBool('is_approved') ?? false;
      final isActive = prefs.getBool('is_active') ?? false;

      setState(() {
        name = 'مرحباً، $userName';
        userData = {
          'id': userId,
          'name': userName,
          'phone': userPhone,
          'email': userEmail,
          'role': userRole,
          'is_approved': isApproved,
          'is_active': isActive,
        };
      });

      // Load order counts
      await _loadOrderCounts();
    } catch (e) {
      print('❌ خطأ في تحميل بيانات المستخدم: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadOrderCounts() async {
    if (userData == null) return;

    try {
      final orderService = OrderService();
      final response = await orderService.getAllOrders();

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data['data'];
        if (responseData != null && responseData['data'] is List) {
          final allOrders = List<Map<String, dynamic>>.from(responseData['data']);
          final currentUserId = userData!['id'];

          // Count orders for delivery user
          int newCount = 0;
          int currentCount = 0;
          int completedCount = 0;

          for (final order in allOrders) {
            final orderStatus = order['status'];
            final orderDeliveryId = order['delivery_id'];

            switch (orderStatus) {
              case 0: // New orders available for all delivery users
                newCount++;
                break;
              case 1: // Orders accepted by this delivery user
                if (orderDeliveryId == currentUserId) {
                  currentCount++;
                }
                break;
              case 2: // Orders completed by this delivery user
                if (orderDeliveryId == currentUserId) {
                  completedCount++;
                }
                break;
            }
          }

          setState(() {
            newOrdersCount = newCount;
            currentOrdersCount = currentCount;
            completedOrdersCount = completedCount;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ خطأ في تحميل عدد الطلبات: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false, // Remove back button
          title: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
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
                    child: IconButton(
                      icon: const Icon(Icons.delivery_dining, color: Colors.white, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationDelivery(phone: widget.phone),
                          ),
                        );
                      },
                    ),
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationDelivery(phone: widget.phone),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadUserDataAndCounts();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildCard(
                                context: context,
                                title: 'الطلبات الجديدة',
                                subtitle: '$newOrdersCount طلب جديد',
                                icon: Icons.sync,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 12),
                              _buildCard(
                                context: context,
                                title: 'الطلبات السابقة',
                                subtitle: '$completedOrdersCount طلب مكتمل',
                                icon: Icons.description_outlined,
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              _buildCard(
                                context: context,
                                title: 'الطلبات الجارية',
                                subtitle: '$currentOrdersCount طلب جاري',
                                icon: Icons.inventory_2_outlined,
                                color: Colors.amber,
                              ),
                              const SizedBox(height: 12),
                              _buildCard(
                                context: context,
                                title: 'تقارير',
                                subtitle: 'إحصائيات شاملة',
                                icon: Icons.bar_chart,
                                color: Colors.green.shade800,
                              ),
                              const SizedBox(height: 12),
                              _buildCard(
                                context: context,
                                title: 'البروفايل',
                                subtitle: 'إعدادات الحساب',
                                icon: Icons.person,
                                color: Colors.indigo,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSpecial = title == 'الطلبات الجارية';

    return GestureDetector(
      onTap: () {
        switch (title) {
          case 'الطلبات الجديدة':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderScreenDesign(phone: widget.phone),
              ),
            );
            break;
          case 'الطلبات السابقة':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PreviousOrdersScreenShope(phone: widget.phone),
              ),
            );
            break;
          case 'الطلبات الجارية':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => order_detailes_shope(phone: widget.phone),
              ),
            );
            break;
          case 'البروفايل':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(phone: widget.phone),
              ),
            );
            break;
          case 'تقارير':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportDelevery(phone: widget.phone),
              ),
            );
            break;
        }
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isSpecial ? Colors.black : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSpecial ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (isLoading)
                SizedBox(
                  height: 12,
                  width: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isSpecial ? Colors.black : Colors.white,
                    ),
                  ),
                )
              else
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSpecial ? Colors.black54 : Colors.white70,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
