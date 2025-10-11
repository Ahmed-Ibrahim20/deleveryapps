import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/Api/order_service.dart';
import 'order_detailes_shope.dart';

class CurrentOrdersPage extends StatefulWidget {
  const CurrentOrdersPage({super.key});

  @override
  State<CurrentOrdersPage> createState() => _CurrentOrdersPageState();
}

class _CurrentOrdersPageState extends State<CurrentOrdersPage> {
  List<Map<String, dynamic>> allOrders = [];
  List<Map<String, dynamic>> groupedOrders = [];
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          'الطلبات الجارية',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        itemCount: currentOrders.length,
        itemBuilder: (context, index) {
          final order = currentOrders[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 4,
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Text(
                  order['orderId'].split('-').last,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                'العميل: ${order['customerName']}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text('العنوان: ${order['address']}'),
                  Text('الإجمالي: ${order['total']} جنيه'),
                  Text('السائق: ${order['driver']}'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 18, color: Colors.deepPurple),
                      const SizedBox(width: 4),
                      Text(
                        order['status'],
                        style: TextStyle(
                          color: order['status'] == 'قيد التوصيل'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.deepPurple),
                onPressed: () {
                  // هنا ممكن تضيف تنقل لتفاصيل الطلب لاحقًا
                },
              ),
            ),
          );
        },
      ),
    );
  }
}