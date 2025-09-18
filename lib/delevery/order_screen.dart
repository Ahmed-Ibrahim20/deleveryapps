import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/Api/order_service.dart';

class OrderScreenDesign extends StatefulWidget {
  final String phone;
  
  const OrderScreenDesign({super.key, required this.phone});

  @override
  State<OrderScreenDesign> createState() => _OrderScreenDesignState();
}

class _OrderScreenDesignState extends State<OrderScreenDesign> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> allOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndOrders();
  }

  Future<void> _loadUserDataAndOrders() async {
    try {
      // Get user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('name') ?? 'غير محدد';
      final userPhone = prefs.getString('phone') ?? widget.phone;
      final userRole = prefs.getInt('role') ?? 0;
      final userId = prefs.getInt('user_id') ?? 0;
      final userEmail = prefs.getString('email') ?? '';
      final isApproved = prefs.getBool('is_approved') ?? false;
      final isActive = prefs.getBool('is_active') ?? false;

      setState(() {
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

      await _loadOrders();
    } catch (e) {
      print('❌ خطأ في تحميل بيانات المستخدم: $e');
      setState(() {
        userData = null;
        isLoading = false;
      });
    }
  }

  Future<void> _loadOrders() async {
    if (userData == null || userData!['id'] == null) {
      setState(() {
        orders = [];
        isLoading = false;
      });
      return;
    }

    try {
      final orderService = OrderService();
      // Use the new method to get orders with status = 0
      final response = await orderService.getNewOrdersForDelivery();

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data['data'];
        if (responseData != null && responseData['data'] is List) {
          final allOrdersFromApi = List<Map<String, dynamic>>.from(
            responseData['data'],
          );

          // Filter orders to show only status = 0 (new orders available for delivery)
          final filteredOrders = allOrdersFromApi.where((order) {
            final orderStatus = order['status'];
            return orderStatus == 0; // Only show orders with status = 0
          }).toList();

          setState(() {
            allOrders = List<Map<String, dynamic>>.from(filteredOrders);
            orders = List<Map<String, dynamic>>.from(filteredOrders);
            isLoading = false;
          });

          return;
        }
      }

      setState(() {
        allOrders = [];
        orders = [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        allOrders = [];
        orders = [];
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الطلبات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applySearch() {
    List<Map<String, dynamic>> filteredOrders = List<Map<String, dynamic>>.from(allOrders);

    if (searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase().trim();
      filteredOrders = filteredOrders.where((order) {
        final orderId = order['id']?.toString().toLowerCase() ?? '';
        final customerName = order['customer_name']?.toString().toLowerCase() ?? '';
        final customerPhone = order['customer_phone']?.toString().toLowerCase() ?? '';
        final customerAddress = order['customer_address']?.toString().toLowerCase() ?? '';

        return orderId.contains(searchLower) ||
            customerName.contains(searchLower) ||
            customerPhone.contains(searchLower) ||
            customerAddress.contains(searchLower);
      }).toList();
    }

    setState(() {
      orders = filteredOrders;
    });
  }

  void _clearSearch() {
    setState(() {
      searchQuery = '';
      _searchController.clear();
    });
    _applySearch();
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    try {
      final orderService = OrderService();
      // Change order status from 0 to 1 (accepted by delivery)
      final response = await orderService.changeOrderStatus(
        order['id'],
        1, // Status 1 = accepted by delivery
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم قبول الطلب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload orders to remove the accepted order from the list
        await _loadOrders();
      } else {
        throw Exception('فشل في قبول الطلب');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في قبول الطلب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'الطلبات المتاحة',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.blue,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (userData == null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'الطلبات المتاحة',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.blue,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لم يتم العثور على بيانات المستخدم',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الطلبات المتاحة',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.blue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await _loadOrders();
          },
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      icon: const Icon(Icons.search, color: Colors.blueAccent),
                      hintText: 'ابحث برقم الطلب أو اسم العميل...',
                      border: InputBorder.none,
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: _clearSearch,
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.trim();
                      });
                      _applySearch();
                    },
                  ),
                ),
              ),
              // Orders List
              Expanded(
                child: _buildOrdersList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.assignment_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty
                  ? 'لا توجد نتائج للبحث'
                  : 'لا توجد طلبات متاحة حالياً',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty
                  ? 'جرب البحث بكلمات أخرى'
                  : 'ستظهر هنا الطلبات الجديدة المتاحة للتوصيل',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final addedBy = order['added_by'] as Map<String, dynamic>?;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Colors.blueAccent,
          width: 1.5,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'طلب رقم ${order['id']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'متاح',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Customer Info
            _buildInfoRow(
              Icons.person,
              'العميل',
              order['customer_name'] ?? 'غير محدد',
              Colors.blue,
            ),
            _buildInfoRow(
              Icons.phone,
              'الهاتف',
              order['customer_phone'] ?? 'غير محدد',
              Colors.green,
            ),
            _buildInfoRow(
              Icons.location_on,
              'العنوان',
              order['customer_address'] ?? 'غير محدد',
              Colors.red,
            ),

            // Store Info
            if (addedBy != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.store,
                'المحل',
                addedBy['name'] ?? 'غير محدد',
                Colors.purple,
              ),
              _buildInfoRow(
                Icons.phone_in_talk,
                'هاتف المحل',
                addedBy['phone'] ?? 'غير محدد',
                Colors.indigo,
              ),
            ],

            const SizedBox(height: 12),

            // Order Date and Delivery Fee
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(order['created_at'] ?? ''),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.local_shipping, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${order['delivery_fee'] ?? '0'} جنيه',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Accept Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _acceptOrder(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'قبول الطلب والبدء في التوصيل',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}