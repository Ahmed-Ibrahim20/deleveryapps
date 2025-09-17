import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/Api/order_service.dart';

class order_detailes_shope extends StatefulWidget {
  final String phone;

  const order_detailes_shope({super.key, required this.phone});

  @override
  State<order_detailes_shope> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<order_detailes_shope> {
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

      print('✅ تم تحميل بيانات المستخدم من SharedPreferences:');
      print('📱 الاسم: $userName');
      print('☎️ الهاتف: $userPhone');
      print('👤 النوع: ${userRole == 0 ? 'أدمن' : userRole == 1 ? 'محل' : 'دليفري'}');
      print('🆔 معرف المستخدم: $userId');

      // Load orders for this delivery user
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
          final allOrders = List<Map<String, dynamic>>.from(responseData['data']);
          
          // Filter orders: status = 2 AND delivery_id matches logged-in user id
          final filteredOrders = allOrders.where((order) {
            final orderStatus = order['status'];
            final orderDeliveryId = order['delivery_id'];
            final currentUserId = userData!['id'];
            
            return orderStatus == 2 && orderDeliveryId == currentUserId;
          }).toList();
          
          setState(() {
            orders = filteredOrders;
            isLoading = false;
          });
          
          print('✅ تم تحميل ${allOrders.length} طلب إجمالي');
          print('✅ تم فلترة ${filteredOrders.length} طلب للدليفري رقم ${userData!['id']} بحالة 2');
          return;
        }
      }

      setState(() {
        orders = [];
        isLoading = false;
      });
    } catch (e) {
      print('❌ خطأ في تحميل الطلبات: $e');
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
              'الطلبات الجارية',
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
              'الطلبات الجارية',
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
          centerTitle: true,
          title: const Text(
            'الطلبات الجارية',
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
        body: RefreshIndicator(
          onRefresh: () async {
            await _loadOrders();
          },
          child: Column(
            children: [
              // User Info Card
              Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.blue,
                        child: Icon(
                          userData!['role'] == 0 ? Icons.admin_panel_settings :
                          userData!['role'] == 1 ? Icons.store :
                          Icons.delivery_dining,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData!['name'] ?? 'غير محدد',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              userData!['phone'] ?? 'غير محدد',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: userData!['role'] == 0 ? Colors.purple :
                                 userData!['role'] == 1 ? Colors.blue :
                                 Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          userData!['role'] == 0 ? 'أدمن' :
                          userData!['role'] == 1 ? 'محل' :
                          'دليفري',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
    // Filter orders based on search
    final filteredOrders = orders.where((order) {
      if (searchQuery.isEmpty) return true;
      
      final orderId = order['id']?.toString().toLowerCase() ?? '';
      final customerName = order['customer_name']?.toString().toLowerCase() ?? '';
      final searchLower = searchQuery.toLowerCase();
      
      return orderId.contains(searchLower) || customerName.contains(searchLower);
    }).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty ? Icons.search_off : Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty ? 'لا توجد نتائج للبحث' : 'لا توجد طلبات جارية حالياً',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty ? 'جرب البحث بكلمات أخرى' : 'ستظهر هنا الطلبات المقبولة للتوصيل',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
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

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final addedBy = order['added_by'] as Map<String, dynamic>?;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'جاري التوصيل',
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
            
            // Phone
            Row(
              children: [
                Icon(Icons.phone, color: Colors.grey, size: 16),
                const SizedBox(width: 6),
                Text(
                  order['customer_phone'] ?? 'غير محدد',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
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
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            // Store Info - Simplified
            if (addedBy != null) ...[
              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade300, height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.store, color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'المحل: ${addedBy['name'] ?? 'غير محدد'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Total Amount - Simplified
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      'المبلغ الإجمالي:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${order['total'] ?? '0'} جنيه',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
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