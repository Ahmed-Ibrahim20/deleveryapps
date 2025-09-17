import 'package:flutter/material.dart';
import '../store/order_detailes_shope.dart';
import '../store/previousordersscreen_shope.dart';
import '../store/Profileshope.dart';

class DriverHomePage extends StatefulWidget {
  final String phone;

  DriverHomePage({Key? key, required this.phone}) : super(key: key);

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  String name = 'مرحباً، مستخدم'; // اسم ثابت بدل جلبه من Firebase
  int unreadCount = 0; // عداد إشعارات ثابت

  @override
  void initState() {
    super.initState();
    // مفيش Firebase هنا، كله ديزاين بس
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
          /* DeliveryNotificationBadge(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        Notification_delivery(phone: widget.phone),
                  ),
                );
                // هنا ممكن تزود اكشنات للإشعارات لاحقاً
              },
              onlyUnread: true,
            ),*/
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              // Refresh ديزاين بس، مش هنعمل حاجة
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
                                icon: Icons.sync,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 12),
                              _buildCard(
                                context: context,
                                title: 'الطلبات السابقة',
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
                                icon: Icons.inventory_2_outlined,
                                color: Colors.amber,
                              ),
                              const SizedBox(height: 12),
                              _buildCard(
                                context: context,
                                title: 'تقارير',
                                icon: Icons.bar_chart,
                                color: Colors.green.shade800,
                              ),
                              const SizedBox(height: 12),
                              _buildCard(
                                context: context,
                                title: 'البروفايل',
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
    required IconData icon,
    required Color color,
  }) {
    final isSpecial = title == 'الطلبات الجارية';

    return GestureDetector(
      onTap: () {
        switch (title) {
          case 'الطلبات الجديدة':
            // TODO: Add new orders screen later
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('الطلبات الجديدة - قريباً')),
            );
            break;
          case 'الطلبات السابقة':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PreviousOrdersScreenShope(phone: widget.phone),
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
            // TODO: Add reports screen later
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('التقارير - قريباً')),
            );
            break;
        }
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 90,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSpecial ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isSpecial ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
