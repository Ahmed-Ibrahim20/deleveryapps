import 'package:flutter/material.dart';
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
      print('🔄 Loading ongoing orders (status = 1)...');
      final response = await _orderService.getOngoingOrders();
      
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data['data'];
        print('📦 API Response: ${response.data}');
        print('📦 Response data type: ${responseData.runtimeType}');
        
        if (responseData != null && responseData['data'] is List) {
          final ongoingOrders = List<Map<String, dynamic>>.from(
            responseData['data'],
          );
          
          print('📦 Total ongoing orders found: ${ongoingOrders.length}');
          
          // طباعة تفاصيل كل طلب للتشخيص
          for (var order in ongoingOrders) {
            print('🔍 Order ${order['id']} - Status: ${order['status']} - Customer: ${order['customer_name']}');
          }
          
          setState(() {
            orders = ongoingOrders;
            isLoading = false;
          });
          
          print('✅ Loaded ${ongoingOrders.length} ongoing orders successfully');
        } else {
          print('❌ responseData["data"] is not a List: ${responseData?['data'].runtimeType}');
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
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
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
      
      return orderId.contains(searchQuery) ||
             customerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
             storeName.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
          backgroundColor: Colors.orange.shade700,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
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
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث برقم الطلب أو اسم العميل أو المتجر...',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.orange.shade500),
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ),
            ),

            // Orders Count
            if (!isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.assignment_turned_in, 
                         color: Colors.orange.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'إجمالي الطلبات الجارية: ${filteredOrders.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Content
            Expanded(
              child: _buildContent(),
            ),
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
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'جاري تحميل الطلبات الجارية...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAcceptedOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
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
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty 
                ? 'لا توجد طلبات جارية حالياً'
                : 'لا توجد نتائج للبحث',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'جرب البحث بكلمات أخرى',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAcceptedOrders,
      color: Colors.orange,
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                colors: [Colors.orange.shade50, Colors.orange.shade100],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'طلب رقم ${order['id'] ?? 'غير محدد'}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800]!,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade500,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'جاري',
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
            color: Colors.blue.shade50,
            borderColor: Colors.blue.shade100,
            children: [
              _buildNamePhoneRow(
                order['store_name'] ?? 'غير محدد',
                order['store_phone'] ?? 'غير محدد',
              ),
              if (order['store_address'] != null)
                _buildAddressRow(order['store_address']),
            ],
          ),

          // Customer Info Section
          _buildCleanSection(
            title: "معلومات العميل",
            color: Colors.green.shade50,
            borderColor: Colors.green.shade100,
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
              color: Colors.purple.shade50,
              borderColor: Colors.purple.shade100,
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
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'إجمالي المبلغ:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${order['total_amount'] ?? '0'} جنيه',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'رسوم التوصيل:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      '${order['delivery_fee'] ?? '0'} جنيه',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
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
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'تاريخ الطلب: ${_formatDate(order['created_at'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
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
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (title == "معلومات المتجر") ...[
                Icon(Icons.store, size: 16, color: Colors.blue[800]!),
                const SizedBox(width: 6),
              ] else if (title == "معلومات العميل") ...[
                Icon(Icons.person, size: 16, color: Colors.green[800]!),
                const SizedBox(width: 6),
              ] else if (title == "معلومات السائق") ...[
                Icon(Icons.delivery_dining, size: 16, color: Colors.purple[800]!),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800]!,
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
                Text(
                  'الاسم: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // الهاتف مع label
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  'هاتف: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200, width: 0.5),
                    ),
                    child: Text(
                      phone,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
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
          Text(
            'العنوان: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              address,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
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
