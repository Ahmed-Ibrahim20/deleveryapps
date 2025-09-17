import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/Api/order_service.dart';

class PreviousOrdersScreenShope extends StatefulWidget {
  final String phone;

  const PreviousOrdersScreenShope({super.key, required this.phone});

  @override
  State<PreviousOrdersScreenShope> createState() =>
      _PreviousOrdersScreenState();
}

class _PreviousOrdersScreenState extends State<PreviousOrdersScreenShope> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndOrders();
  }

  Future<void> _loadUserDataAndOrders() async {
    try {
      // Get user data from SharedPreferences (stored during login)
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
      final response = await orderService.getAllOrders();

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data['data'];
        if (responseData != null && responseData['data'] is List) {
          final allOrders = List<Map<String, dynamic>>.from(
            responseData['data'],
          );

          // Filter orders based on user role
          final filteredOrders = allOrders.where((order) {
            final orderStatus = order['status'];
            final currentUserId = userData!['id'];
            final currentUserRole = userData!['role'];

            // For delivery users (role = 1): filter by delivery_id
            if (currentUserRole == 1) {
              final orderDeliveryId = order['delivery_id'];
              return orderStatus == 3 && orderDeliveryId == currentUserId;
            } 
            // For store users (role = 2): filter by user_add_id
            else {
              final orderUserAddId = order['user_add_id'];
              return orderStatus == 3 && orderUserAddId == currentUserId;
            }
          }).toList();

          setState(() {
            orders = filteredOrders;
            isLoading = false;
          });

          return;
        }
      }

      setState(() {
        orders = [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text(
              'الطلبات السابقة',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            backgroundColor: Colors.blue,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
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
            centerTitle: true,
            title: const Text(
              'الطلبات السابقة',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            backgroundColor: Colors.blue,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
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
                SizedBox(height: 8),
                Text(
                  'يرجى تسجيل الدخول مرة أخرى',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
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
          backgroundColor: Colors.blue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: const [
              Expanded(
                child: Text(
                  'سجل الطلبات السابقة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.history, color: Colors.blueAccent),
            ],
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
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'ابحث برقم الطلب أو اسم العميل...',
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.blueAccent),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Orders List
              Expanded(child: _buildOrdersList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    // Filter orders based on search
    final filteredOrders = orders.where((order) {
      if (searchQuery.isEmpty) return true;

      final orderId = order['id']?.toString().toLowerCase() ?? '';
      final customerName =
          order['customer_name']?.toString().toLowerCase() ?? '';
      final searchLower = searchQuery.toLowerCase();

      return orderId.contains(searchLower) ||
          customerName.contains(searchLower);
    }).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.history_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty
                  ? 'لا توجد نتائج للبحث'
                  : 'لا توجد طلبات سابقة حالياً',
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
                  : 'ستظهر هنا الطلبات المكتملة',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  // Make phone call function
  void _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isNotEmpty && phoneNumber != 'غير محدد') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('جاري فتح الهاتف للرقم: $phoneNumber')),
        );
      }
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final addedBy = order['added_by'] as Map<String, dynamic>?;
    final delivery = order['delivery'] as Map<String, dynamic>?;
    final currentUserRole = userData!['role'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    'مكتمل',
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

            // Customer Info - Simplified
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order['customer_name'] ?? 'غير محدد',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Phone - Clickable
            GestureDetector(
              onTap: () => _makePhoneCall(order['customer_phone'] ?? ''),
              child: Row(
                children: [
                  Icon(Icons.phone, color: Colors.blue, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    order['customer_phone'] ?? 'غير محدد',
                    style: TextStyle(
                      fontSize: 13, 
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Address
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order['customer_address'] ?? 'غير محدد',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Show different info based on user role
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade300, height: 1),
            const SizedBox(height: 8),
            
            // For delivery users (role = 1): show store info (added_by)
            if (currentUserRole == 1 && addedBy != null) ...[
              Row(
                children: [
                  Icon(Icons.store, color: Colors.blue, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المحل: ${addedBy['name'] ?? 'غير محدد'}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _makePhoneCall(addedBy['phone'] ?? ''),
                          child: Text(
                            'هاتف: ${addedBy['phone'] ?? 'غير محدد'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ]
            // For store users (role = 2): show delivery info
            else if (currentUserRole == 2 && delivery != null) ...[
              Row(
                children: [
                  Icon(Icons.delivery_dining, color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الدليفري: ${delivery['name'] ?? 'غير محدد'}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _makePhoneCall(delivery['phone'] ?? ''),
                          child: Text(
                            'هاتف: ${delivery['phone'] ?? 'غير محدد'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Delivery Fee Only
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_shipping, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      'رسوم التوصيل:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${order['delivery_fee'] ?? '0'} جنيه',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
