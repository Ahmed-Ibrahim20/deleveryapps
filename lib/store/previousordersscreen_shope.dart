import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/Api/order_service.dart';
import '../services/pdf_service.dart';

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
  List<Map<String, dynamic>> allOrders = <Map<String, dynamic>>[];
  bool isLoading = true;

  // Date filter variables
  DateTime? fromDate;
  DateTime? toDate;

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
          final allOrdersFromApi = List<Map<String, dynamic>>.from(
            responseData['data'],
          );

          // Filter orders based on user role
          final filteredOrders = allOrdersFromApi.where((order) {
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
            allOrders = List<Map<String, dynamic>>.from(filteredOrders); // Store all orders
            orders = List<Map<String, dynamic>>.from(filteredOrders); // Display all initially
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
          backgroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.grey.shade200,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.grey.shade700, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Icon(Icons.history, color: Colors.blue.shade600, size: 22),
              const SizedBox(width: 8),
              const Text(
                'الطلبات السابقة',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actions: [
            // PDF Download Button
            IconButton(
              onPressed: orders.isNotEmpty ? _downloadPDF : null,
              icon: Icon(
                Icons.download,
                color: orders.isNotEmpty ? Colors.blue.shade600 : Colors.grey,
                size: 20,
              ),
              tooltip: 'تحميل PDF',
            ),
            // PDF Preview Button
            IconButton(
              onPressed: orders.isNotEmpty ? _previewPDF : null,
              icon: Icon(
                Icons.preview,
                color: orders.isNotEmpty ? Colors.blue.shade600 : Colors.grey,
                size: 20,
              ),
              tooltip: 'معاينة PDF',
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                '${orders.length}',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey.shade50,
        body: RefreshIndicator(
          onRefresh: () async {
            await _loadOrders();
          },
          child: Column(
            children: [
              // Date Filter Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                fromDate != null ? _formatDate(fromDate!.toIso8601String()) : 'من تاريخ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: fromDate != null ? Colors.black87 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                toDate != null ? _formatDate(toDate!.toIso8601String()) : 'إلى تاريخ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: toDate != null ? Colors.black87 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (fromDate != null || toDate != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _clearDateFilters,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.clear, size: 16, color: Colors.red.shade600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Search bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث برقم الطلب أو اسم العميل...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey.shade600, size: 18),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey.shade600, size: 18),
                            onPressed: _clearSearch,
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.trim();
                    });
                    _applyFilters();
                  },
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
    // Use the already filtered orders from _applyFilters()
    final filteredOrders = orders;

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  // Make phone call function
  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber == 'غير محدد') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رقم الهاتف غير متوفر'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يمكن فتح تطبيق الهاتف'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاتصال: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Format date to DD-MM-YYYY
  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Date picker function
  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? fromDate ?? DateTime.now()
          : toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: isFromDate ? 'اختر التاريخ من' : 'اختر التاريخ إلى',
      cancelText: 'إلغاء',
      confirmText: 'موافق',
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
        _applyFilters();
      });
    }
  }

  // Apply date and search filters
  void _applyFilters() {
    List<Map<String, dynamic>> filteredOrders = List<Map<String, dynamic>>.from(allOrders);

    // Apply date filter first
    if (fromDate != null || toDate != null) {
      filteredOrders = filteredOrders.where((order) {
        try {
          final createdAt = order['created_at']?.toString();
          if (createdAt == null || createdAt.isEmpty) return false;
          
          // Parse the date string (handles both formats: "2025-09-16T13:28:05.000000Z" and "2025-09-16")
          DateTime orderDate;
          if (createdAt.contains('T')) {
            // ISO format with time
            orderDate = DateTime.parse(createdAt);
          } else {
            // Simple date format
            orderDate = DateTime.parse(createdAt);
          }
          
          // Convert to date only for comparison
          final orderDateOnly = DateTime(orderDate.year, orderDate.month, orderDate.day);

          bool passesFromDate = true;
          bool passesToDate = true;
          
          if (fromDate != null) {
            final fromDateOnly = DateTime(fromDate!.year, fromDate!.month, fromDate!.day);
            passesFromDate = orderDateOnly.isAtSameMomentAs(fromDateOnly) || orderDateOnly.isAfter(fromDateOnly);
          }
          
          if (toDate != null) {
            final toDateOnly = DateTime(toDate!.year, toDate!.month, toDate!.day);
            passesToDate = orderDateOnly.isAtSameMomentAs(toDateOnly) || orderDateOnly.isBefore(toDateOnly);
          }

          return passesFromDate && passesToDate;
        } catch (e) {
          print('❌ خطأ في تحليل التاريخ: $e - التاريخ: ${order['created_at']}');
          return false; // Exclude orders with invalid dates
        }
      }).toList();
    }

    // Apply search filter
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

  // Clear date filters
  void _clearDateFilters() {
    setState(() {
      fromDate = null;
      toDate = null;
    });
    _applyFilters();
  }

  // Clear search
  void _clearSearch() {
    setState(() {
      searchQuery = '';
      _searchController.clear();
    });
    _applyFilters();
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final addedBy = order['added_by'] as Map<String, dynamic>?;
    final delivery = order['delivery'] as Map<String, dynamic>?;
    final currentUserRole = userData!['role'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.receipt, color: Colors.blue.shade600, size: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'طلب #${order['id']}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'مكتمل',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${order['delivery_fee'] ?? '0'} ج',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Customer Info
          Row(
            children: [
              Icon(Icons.person, color: Colors.grey.shade600, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order['customer_name'] ?? 'غير محدد',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _makePhoneCall(order['customer_phone'] ?? ''),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone, color: Colors.blue.shade600, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        order['customer_phone'] ?? 'غير محدد',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Address
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey.shade600, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order['customer_address'] ?? 'غير محدد',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          // Store/Driver Info
          if (currentUserRole == 1 && addedBy != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.store, color: Colors.orange.shade600, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    addedBy['name'] ?? 'غير محدد',
                    style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _makePhoneCall(addedBy['phone'] ?? ''),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      addedBy['phone'] ?? 'غير محدد',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (currentUserRole == 2 && delivery != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.delivery_dining, color: Colors.green.shade600, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    delivery['name'] ?? 'غير محدد',
                    style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _makePhoneCall(delivery['phone'] ?? ''),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      delivery['phone'] ?? 'غير محدد',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 6),
          
          // Date
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey.shade600, size: 12),
              const SizedBox(width: 4),
              Text(
                _formatDate(order['created_at'] ?? ''),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // PDF Download Function
  Future<void> _downloadPDF() async {
    if (orders.isEmpty) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('جاري إنشاء ملف PDF...'),
            ],
          ),
        ),
      );

      // Generate filename with date range
      String fileName = 'تقرير_الطلبات_السابقة_${userData?['name'] ?? 'المتجر'}_${DateTime.now().toString().substring(0, 19).replaceAll(':', '-')}.pdf';

      // Create PDF data for shop orders
      Map<String, dynamic> pdfData = {
        'shop_name': userData?['name'] ?? 'المتجر',
        'phone': userData?['phone'] ?? '',
        'total_orders': orders.length,
        'total_delivery_fees': orders.fold(0.0, (sum, order) => sum + (double.tryParse(order['delivery_fee']?.toString() ?? '0') ?? 0)),
        'orders': orders,
        'from_date': fromDate?.toIso8601String(),
        'to_date': toDate?.toIso8601String(),
      };

      // Generate PDF
      String result = await PDFService.generateShopOrdersPDF(pdfData, fileName);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.contains('تم تحميل') ? result : 'تم حفظ الملف بنجاح'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء ملف PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // PDF Preview Function
  Future<void> _previewPDF() async {
    if (orders.isEmpty) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('جاري تحضير المعاينة...'),
            ],
          ),
        ),
      );

      // Create PDF data for shop orders
      Map<String, dynamic> pdfData = {
        'shop_name': userData?['name'] ?? 'المتجر',
        'phone': userData?['phone'] ?? '',
        'total_orders': orders.length,
        'total_delivery_fees': orders.fold(0.0, (sum, order) => sum + (double.tryParse(order['delivery_fee']?.toString() ?? '0') ?? 0)),
        'orders': orders,
        'from_date': fromDate?.toIso8601String(),
        'to_date': toDate?.toIso8601String(),
      };

      // Preview PDF
      await PDFService.previewShopOrdersPDF(pdfData);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في معاينة ملف PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
