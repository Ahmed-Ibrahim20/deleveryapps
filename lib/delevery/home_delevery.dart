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
import '../services/Api/user_service.dart';
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
  bool isLoading = true;

  // متغير للتحكم في حالة النشاط
  bool isActiveNow = false;
  bool isTogglingStatus = false; // متغير لحالة التحميل عند تبديل الحالة

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // تهيئة الإشعارات
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final provider =
              Provider.of<NotificationProvider>(context, listen: false);
          provider.updateUserRole(UserRole.driver);
          provider.fetchNotifications();
        } catch (e) {
          print('❌ Error initializing NotificationProvider: $e');
        }
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('name') ?? 'مستخدم';
      final userPhone = prefs.getString('phone') ?? widget.phone;
      final userRole = prefs.getInt('role') ?? 0;
      final userId = prefs.getInt('user_id') ?? 0;
      final userEmail = prefs.getString('email') ?? '';
      final isApproved = prefs.getBool('is_approved') ?? false;
      // تحميل حالة النشاط المحفوظة (أولوية للـ is_available ثم is_active)
      final savedIsAvailable = prefs.getBool('is_available');
      final savedIsActive = prefs.getBool('is_active') ?? false;
      final finalActiveStatus = savedIsAvailable ?? savedIsActive;

      setState(() {
        name = 'مرحباً، $userName';
        userData = {
          'id': userId,
          'name': userName,
          'phone': userPhone,
          'email': userEmail,
          'role': userRole,
          'is_approved': isApproved,
          'is_active': finalActiveStatus,
          'is_available': finalActiveStatus,
        };
        // تحديث حالة النشاط الحالية بناءً على ما تم حفظه
        isActiveNow = finalActiveStatus;
        isLoading = false;
      });
    } catch (e) {
      print('❌ خطأ في تحميل بيانات المستخدم: $e');
      setState(() {
        isLoading = false;
      });
    }
  }


  // دالة تحديث حالة النشاط باستخدام API
  Future<void> _toggleActiveStatus() async {
    if (isTogglingStatus) return; // منع النقر المتكرر

    setState(() {
      isTogglingStatus = true;
    });

    try {
      final userService = UserService();
      final response = await userService.toggleMyAvailability(isActiveNow);

      print('🔄 Toggle Availability Response: ${response.statusCode}');
      print('📦 Response Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        
        if (responseData['status'] == true && responseData['data'] != null) {
          final newAvailabilityStatus = responseData['data']['is_available'] ?? false;
          final statusMessage = responseData['message'] ?? 'تم تحديث الحالة';
          
          // تحديث الحالة المحلية
          setState(() {
            isActiveNow = newAvailabilityStatus;
          });
          
          // حفظ الحالة في SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_active', newAvailabilityStatus);
          await prefs.setBool('is_available', newAvailabilityStatus);
          
          // عرض رسالة نجاح
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  statusMessage,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          
          print('✅ حالة التوفر تم تحديثها إلى: $newAvailabilityStatus');
        } else {
          throw Exception('استجابة غير صحيحة من الخادم');
        }
      } else {
        throw Exception('فشل في تحديث حالة التوفر');
      }
    } catch (e) {
      print('❌ خطأ في تبديل حالة التوفر: $e');
      
      // عرض رسالة خطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ في تحديث حالة التوفر. حاول مرة أخرى.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'حاول مرة أخرى',
              textColor: Colors.white,
              onPressed: () => _toggleActiveStatus(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isTogglingStatus = false;
        });
      }
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
          automaticallyImplyLeading: false,
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
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    badgeStyle: const badges.BadgeStyle(
                      badgeColor: Colors.red,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delivery_dining,
                          color: Colors.white, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NotificationDelivery(phone: widget.phone),
                          ),
                        );
                      },
                    ),
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.notifications_none,
                      color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            NotificationDelivery(phone: widget.phone),
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
            onRefresh: _loadUserData,
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
                                subtitle: 'طلبات جديدة',
                                icon: Icons.sync,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 12),
                              _buildCard(
                                context: context,
                                title: 'الطلبات السابقة',
                                subtitle: 'طلبات سابقة',
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
                                subtitle: 'طلبات جارية',
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

        // -->> زر تبديل حالة التوفر مع API <<--
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isTogglingStatus 
                  ? Colors.grey 
                  : (isActiveNow ? Colors.green : Colors.red),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: isTogglingStatus ? 0 : 3,
            ),
            onPressed: isTogglingStatus ? null : _toggleActiveStatus,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isTogglingStatus) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "جاري التحديث...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  Icon(
                    isActiveNow ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActiveNow ? "متاح للتوصيل" : "غير متاح للتوصيل",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
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
                builder: (context) =>
                    order_detailes_shope(phone: widget.phone),
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
              const Spacer(),
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