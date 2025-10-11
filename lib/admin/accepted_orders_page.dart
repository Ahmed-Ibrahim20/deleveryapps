import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/Api/order_service.dart';

class AcceptedOrdersPage extends StatefulWidget {
  const AcceptedOrdersPage({super.key});

  @override
  State<AcceptedOrdersPage> createState() => _AcceptedOrdersPageState();
}

class _AcceptedOrdersPageState extends State<AcceptedOrdersPage> {
  final OrderService _orderService = OrderService();
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAcceptedOrders();
  }

  Future<void> _loadAcceptedOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('🔄 Loading accepted orders (status = 1)...');
      final response = await _orderService.getAllOrders();

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data['data'];
        print('📦 API Response: ${response.data}');
        print('📦 Response data type: ${responseData.runtimeType}');

        if (responseData != null && responseData['data'] is List) {
          final allOrders = List<Map<String, dynamic>>.from(
            responseData['data'],
          );

          // فلترة الطلبات المقبولة فقط (status = 1)
          final acceptedOrders = allOrders.where((order) {
            final orderStatus = order['status'];
            return orderStatus == 1; // فقط الطلبات المقبولة
          }).toList();

          print('📦 Total orders found: ${allOrders.length}');
          print('📦 Accepted orders (status = 1): ${acceptedOrders.length}');

          // طباعة تفاصيل كل طلب مقبول للتشخيص
          for (var order in acceptedOrders) {
            print(
              '🔍 Order ${order['id']} - Status: ${order['status']} - Customer: ${order['customer_name']}',
            );
            print('🏪 Store info from added_by: ${order['added_by']}');
          }

          setState(() {
            orders = acceptedOrders;
            isLoading = false;
          });

          print('✅ Loaded ${acceptedOrders.length} accepted orders successfully');
        } else {
          print(
            '❌ responseData["data"] is not a List: ${responseData?['data'].runtimeType}',
          );
          print('❌ Full responseData: $responseData');
          setState(() {
            orders = [];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'فشل في تحميل البيانات: ${response.statusMessage}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading accepted orders: $e');
      print('❌ Error type: ${e.runtimeType}');

      String userFriendlyError;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        userFriendlyError = 'تعذر الاتصال بالخادم. تأكد من اتصال الإنترنت.';
      } else if (e.toString().contains('TimeoutException')) {
        userFriendlyError = 'انتهت مهلة الاتصال. حاول مرة أخرى.';
      } else if (e.toString().contains('FormatException')) {
        userFriendlyError = 'خطأ في تنسيق البيانات المستلمة من الخادم.';
      } else {
        userFriendlyError = 'حدث خطأ غير متوقع. حاول مرة أخرى.';
      }

      setState(() {
        errorMessage = userFriendlyError;
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredOrders {
    if (searchQuery.isEmpty) return orders;

    return orders.where((order) {
      final orderId = order['id']?.toString() ?? '';
      final customerName = order['customer_name']?.toString() ?? '';
      final storeName = order['store_name']?.toString() ?? '';
      final addedByName = order['added_by']?['name']?.toString() ?? '';
      final addedByPhone = order['added_by']?['phone']?.toString() ?? '';

      return orderId.contains(searchQuery) ||
          customerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          storeName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          addedByName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          addedByPhone.contains(searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'الطلبات المقبولة',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: const Color(0xFF2C3E50),
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.3),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: _loadAcceptedOrders,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF34495E)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF34495E).withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'ابحث برقم الطلب أو اسم العميل أو المتجر...',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Color(0xFF5D6D7E)),
                    hintStyle: TextStyle(color: Color(0xFF85929E)),
                  ),
                ),
              ),
            ),

            // Orders Count
            if (!isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5DADE2), Color(0xFF3498DB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF3498DB).withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.assignment_turned_in,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'إجمالي الطلبات المقبولة: ${filteredOrders.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E44AD)),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'جاري تحميل الطلبات المقبولة...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF5D6D7E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFE74C3C)),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF5D6D7E),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAcceptedOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E44AD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Color(0xFFADB5BD),
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty
                  ? 'لا توجد طلبات مقبولة حالياً'
                  : 'لا توجد نتائج للبحث',
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF5D6D7E),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'جرب البحث بكلمات أخرى',
                style: TextStyle(fontSize: 14, color: Color(0xFF85929E)),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAcceptedOrders,
      color: const Color(0xFF8E44AD),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(filteredOrders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    // طباعة تفاصيل الطلب للتشخيص
    print('🔍 Order details: $order');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF34495E), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C3E50).withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF34495E), Color(0xFF2C3E50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFF1B2631), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'طلب رقم ${order['id'] ?? 'غير محدد'}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'مقبول',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Store Info Section
          _buildCleanSection(
            title: "معلومات المتجر",
            color: const Color(0xFFEBF0F5),
            borderColor: const Color(0xFFD5DBDB),
            children: [
              _buildNamePhoneRow(
                // محاولة الحصول على اسم المتجر من added_by أولاً، ثم من store_name
                order['added_by']?['name'] ?? order['store_name'] ?? 'غير محدد',
                // محاولة الحصول على هاتف المتجر من added_by أولاً، ثم من store_phone
                order['added_by']?['phone'] ??
                    order['store_phone'] ??
                    'غير محدد',
              ),
              // عرض العنوان إذا كان متوفر
              if (order['store_address'] != null)
                _buildAddressRow(order['store_address']),
            ],
          ),

          // Customer Info Section
          _buildCleanSection(
            title: "معلومات العميل",
            color: const Color(0xFFEBF5FB),
            borderColor: const Color(0xFFAED6F1),
            children: [
              _buildNamePhoneRow(
                order['customer_name'] ?? 'غير محدد',
                order['customer_phone'] ?? 'غير محدد',
              ),
              if (order['delivery_address'] != null)
                _buildAddressRow(order['delivery_address']),
            ],
          ),
          // Driver Info Section
          if (order['delivery_name'] != null)
            _buildCleanSection(
              title: "معلومات السائق",
              color: const Color(0xFFEAF2F8),
              borderColor: const Color(0xFFABB2B9),
              children: [
                _buildNamePhoneRow(
                  order['delivery_name'] ?? 'غير محدد',
                  order['delivery_phone'] ?? 'غير محدد',
                ),
              ],
            ),

          // Order Details Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFEF9E7), Color(0xFFFCF3CF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                top: BorderSide(color: Color(0xFFD5DBDB), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'رسوم التوصيل:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5D6D7E),
                  ),
                ),
                Text(
                  '${order['delivery_fee'] ?? '0'} جنيه',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF27AE60),
                  ),
                ),
              ],
            ),
          ),

          // Order Date
          if (order['created_at'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Color(0xFF5D6D7E),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'تاريخ الطلب: ${_formatDate(order['created_at'])}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5D6D7E),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCleanSection({
    required String title,
    required Color color,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (title == "معلومات المتجر") ...[
                const Icon(Icons.store, size: 16, color: Color(0xFF3498DB)),
                const SizedBox(width: 6),
              ] else if (title == "معلومات العميل") ...[
                const Icon(Icons.person, size: 16, color: Color(0xFF8E44AD)),
                const SizedBox(width: 6),
              ] else if (title == "معلومات السائق") ...[
                const Icon(
                  Icons.delivery_dining,
                  size: 16,
                  color: Color(0xFF27AE60),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  // إضافة دالة الاتصال
  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber == 'غير محدد' || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رقم الهاتف غير متوفر'),
          backgroundColor: Color(0xFFE74C3C),
        ),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يمكن فتح تطبيق الهاتف'),
              backgroundColor: Color(0xFFE74C3C),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء محاولة الاتصال'),
            backgroundColor: Color(0xFFE74C3C),
          ),
        );
      }
    }
  }

  Widget _buildNamePhoneRow(String name, String phone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // الاسم مع label
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const Text(
                  'الاسم: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5D6D7E),
                  ),
                ),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // الهاتف مع label قابل للنقر
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Text(
                  'هاتف: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5D6D7E),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _makePhoneCall(phone),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF27AE60), Color(0xFF229954)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF27AE60).withOpacity(0.4),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              phone,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(String address) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Text(
            'العنوان: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5D6D7E),
            ),
          ),
          Expanded(
            child: Text(
              address,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF34495E),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'غير محدد';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
