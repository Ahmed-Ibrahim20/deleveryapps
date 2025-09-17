//import 'package:delivery_traning/AccountRequestsPage.dart';
//import 'package:delivery_traning/User%20Accounts%20Page.dart';
//import 'package:delivery_traning/delevery_page.dart';
//import 'package:delivery_traning/notifications_page.dart';
//import 'package:delivery_traning/profile_page.dart';
//import 'package:delivery_traning/shop_page1.dart';
//import 'package:delivery_traning/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app_delevery1/admin/PendingUsersPage.dart';
import 'package:my_app_delevery1/admin/signup_screen.dart';
import 'package:my_app_delevery1/admin/UserAccounts.dart';
import 'package:my_app_delevery1/admin/ShopPage.dart';
import 'package:my_app_delevery1/admin/DeleveryPage.dart';
import 'package:my_app_delevery1/admin/ProfilePage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchQuery = '';
  String selectedFilter = 'اليوم';
  DateTime? selectedDate;
  DateTime? selectedMonth;
  String adminName = 'توصيل الطلبات'; // Default title
  bool isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminName = prefs.getString('admin_name');

      if (!mounted) return;

      if (adminName != null && adminName.isNotEmpty) {
        setState(() {
          this.adminName = adminName;
          isLoadingName = false;
        });
        return;
      }

      // fallback: default name
      if (!mounted) return;
      setState(() {
        isLoadingName = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingName = false;
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
          automaticallyImplyLeading: false,
          title: Text(
            isLoadingName ? 'جاري التحميل...' : adminName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white, size: 40),
              onPressed: () {
                /*Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(),
                  ),
                );*/
              },
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.2,
                        padding: const EdgeInsets.only(bottom: 40),
                        children: [
                          _buildGridCard(context, 'التقارير التفصيلية', Icons.bar_chart, Colors.green.shade600),
                          _buildGridCard(context, 'إدارة المتاجر', Icons.storefront_outlined, Colors.blue.shade600),
                          _buildGridCard(context, 'إدارة السائقين', Icons.delivery_dining_outlined, Colors.orange.shade600),
                          _buildGridCard(context, 'إضافة أدمن جديد', Icons.person_add, Colors.purple.shade600),
                          _buildCard(
                            context,
                            'البروفايل',
                            Icons.person,
                            Colors.purple,
                            () async {
                              final prefs = await SharedPreferences.getInstance();
                              final phone = prefs.getString('admin_phone') ?? '';
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ProfilePage(phone: phone)),
                              );
                            },
                          ),
                          _buildGridCard(context, 'طلبات فتح حساب', Icons.pending_actions, Colors.lightBlue.shade600),
                          _buildGridCard(context, 'حسابات المستخدمين', Icons.manage_accounts, Colors.amber.shade600),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        switch (title) {
          case 'طلبات فتح حساب':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PendingUsersPage()),
            );
            break;
          case 'إضافة أدمن جديد':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminSignupScreen()),
            );
            break;
          case 'حسابات المستخدمين':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserAccountsScreen()),
            );
            break;
          case 'إدارة المتاجر':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShopPage()),
            );
            break;
          case 'إدارة السائقين':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DeleveryPage()),
            );
            break;
          default:
            // Handle other cards if needed
            break;
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(2, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(2, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}