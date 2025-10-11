import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/Api/order_service.dart';
import '../delevery/home_delevery.dart';

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
  List<Map<String, dynamic>> allOrders = <Map<String, dynamic>>[];
  bool isLoading = true;

  DateTime? fromDate;
  DateTime? toDate;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndOrders();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber == 'غير محدد') return;

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يمكن الاتصال بالرقم: $phoneNumber')),
        );
      }
    }
  }

  Future<void> _completeDelivery(dynamic orderId) async {
    try {
      // عرض dialog للتأكيد
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تأكيد إكمال التوصيل'),
          content: const Text('هل أنت متأكد من إكمال هذا الطلب؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // عرض loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(strokeWidth: 2),
                SizedBox(width: 16),
                Text('جاري إكمال التوصيل...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // محاولة إكمال التوصيل مع retry logic
      final orderService = OrderService();

      // محاولة أولى
      try {
        final response = await orderService
            .changeOrderStatus(orderId, 3)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw Exception(
                  'انتهت مهلة الاتصال. تحقق من الاتصال بالإنترنت.',
                );
              },
            );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ تم إكمال التوصيل بنجاح!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }

          // التوجه لصفحة الهوم بعد إكمال التوصيل بنجاح
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => DriverHomePage(phone: widget.phone),
              ),
              (route) => false,
            );
          }
          return;
        } else {
          throw Exception('خطأ من الخادم: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('❌ المحاولة الأولى فشلت: $e');

        // محاولة ثانية بعد ثانيتين
        await Future.delayed(const Duration(seconds: 2));

        try {
          final response = await orderService
              .changeOrderStatus(orderId, 3)
              .timeout(const Duration(seconds: 20));

          if (response.statusCode == 200 || response.statusCode == 201) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ تم إكمال التوصيل بنجاح!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }

            // التوجه لصفحة الهوم بعد إكمال التوصيل بنجاح
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => DriverHomePage(phone: widget.phone),
                ),
                (route) => false,
              );
            }
            return;
          }
        } catch (retryError) {
          debugPrint('❌ المحاولة الثانية فشلت: $retryError');
          rethrow;
        }

        rethrow;
      }
    } catch (e) {
      debugPrint('❌ خطأ في إكمال التوصيل: $e');

      String errorMessage = 'خطأ في إكمال التوصيل';

      if (e.toString().contains('connection error') ||
          e.toString().contains('XMLHttpRequest') ||
          e.toString().contains('network')) {
        errorMessage =
            'خطأ في الاتصال بالإنترنت. تحقق من الاتصال وحاول مرة أخرى.';
      } else if (e.toString().contains('timeout') ||
          e.toString().contains('انتهت مهلة')) {
        errorMessage =
            'انتهت مهلة الاتصال. تحقق من سرعة الإنترنت وحاول مرة أخرى.';
      } else if (e.toString().contains('401')) {
        errorMessage = 'خطأ في التوثيق. قم بتسجيل الدخول مرة أخرى.';
      } else if (e.toString().contains('403')) {
        errorMessage = 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';
      } else if (e.toString().contains('404')) {
        errorMessage = 'الطلب غير موجود أو تم حذفه.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'خطأ في الخادم. حاول مرة أخرى لاحقاً.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'حاول مرة أخرى',
              textColor: Colors.white,
              onPressed: () => _completeDelivery(orderId),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadUserDataAndOrders() async {
    try {
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
      debugPrint('❌ خطأ في تحميل بيانات المستخدم: $e');
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

          final filteredOrders = allOrders.where((order) {
            final orderStatus = order['status'];
            final currentUserId = userData!['id'];
            final currentUserRole = userData!['role'];

            // فلترة الطلبات بحالة مقبولة أو جارية فقط
            if (orderStatus != 1 && orderStatus != 2) {
              return false;
            }

            if (currentUserRole == 1) {
              // للسائقين: عرض الطلبات التي تم تعيينهم لها
              final orderDeliveryId = order['delivery_id'];
              return orderDeliveryId != null &&
                  orderDeliveryId == currentUserId;
            } else if (currentUserRole == 2) {
              // للمحلات: عرض الطلبات التي أضافوها
              final orderUserAddId = order['user_add_id'];
              return orderUserAddId != null && orderUserAddId == currentUserId;
            } else {
              // للأدمن: عرض جميع الطلبات المقبولة والجارية
              return true;
            }
          }).toList();

          setState(() {
            this.allOrders.clear();
            this.allOrders.addAll(filteredOrders);
            orders = List.from(filteredOrders);
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
              'الطلبات الجارية',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            backgroundColor: Colors.blue.shade700,
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
            backgroundColor: Colors.blue.shade700,
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
          backgroundColor: Colors.blue.shade700,
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
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ابحث برقم الطلب أو اسم العميل...',
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.blue.shade500,
                      ),
                      hintStyle: TextStyle(color: Colors.grey.shade500),
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

              Expanded(child: _buildOrdersList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    final filteredOrders = allOrders.where((order) {
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
                  : Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty
                  ? 'لا توجد نتائج للبحث'
                  : 'لا توجد طلبات جارية حالياً',
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
                  : 'ستظهر هنا الطلبات المقبولة والجارية',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
    final delivery = order['delivery'] as Map<String, dynamic>?;
    final currentUserRole = userData!['role'];

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
                colors: [Colors.blue.shade50, Colors.blue.shade100],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'طلب رقم ${order['id']}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800]!,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: order['status'] == 1
                        ? Colors.orange.shade500
                        : Colors.green.shade500,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order['status'] == 1 ? 'مقبول' : 'جاري التوصيل',
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

          // Store Info Section (For Delivery Users)
          if (currentUserRole == 1 && addedBy != null)
            _buildCleanSection(
              title: "معلومات المتجر",
              color: Colors.blue.shade50,
              borderColor: Colors.blue.shade100,
              children: [
                _buildNamePhoneRow(
                  addedBy['name'] ?? 'غير محدد',
                  addedBy['phone'] ?? 'غير محدد',
                ),
                _buildAddressRow(addedBy['address'] ?? 'غير محدد'),
              ],
            ),

          // Customer Info Section (Always shown)
          _buildCleanSection(
            title: "معلومات العميل",
            color: Colors.green.shade50,
            borderColor: Colors.green.shade100,
            children: [
              _buildNamePhoneRow(
                order['customer_name'] ?? 'غير محدد',
                order['customer_phone'] ?? 'غير محدد',
              ),
              _buildAddressRow(order['customer_address'] ?? 'غير محدد'),
            ],
          ),

          // Delivery Info Section (For Store Users)
          if (currentUserRole == 2 && delivery != null)
            _buildCleanSection(
              title: "معلومات السائق",
              color: Colors.orange.shade50,
              borderColor: Colors.orange.shade100,
              children: [
                _buildNamePhoneRow(
                  delivery['name'] ?? 'غير محدد',
                  delivery['phone'] ?? 'غير محدد',
                ),
              ],
            ),

          // Delivery Fee Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border(
                top: BorderSide(color: Colors.orange.shade200, width: 1),
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
          ),

          // Complete Delivery Button (For Delivery Users Only)
          if (currentUserRole == 1)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => _completeDelivery(order['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'إكمال التوصيل',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
                Icon(Icons.store, size: 16, color: Colors.blue[800]!),
                const SizedBox(width: 6),
              ] else if (title == "معلومات العميل") ...[
                Icon(Icons.person, size: 16, color: Colors.green[800]!),
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

  // عرض الاسم والهاتف في سطر واحد
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
                  child: GestureDetector(
                    onTap: () => _makePhoneCall(phone),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 0.5,
                        ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // عرض العنوان مع label
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
}
