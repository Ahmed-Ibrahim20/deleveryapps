import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/Api/order_service.dart';

class NewOrdersScreen extends StatefulWidget {
  final String phone;

  const NewOrdersScreen({super.key, required this.phone});

  @override
  State<NewOrdersScreen> createState() => _NewOrdersScreenState();
}

class _NewOrdersScreenState extends State<NewOrdersScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? storeData;
  bool isLoading = true;
  String? extractedPhone;

  final Map<String, TextEditingController> controllers = {
    'orderId': TextEditingController(),
    'client': TextEditingController(),
    'clientAddress': TextEditingController(),
    'clientPhone': TextEditingController(),
    'deliveryCost': TextEditingController(),
    'appCommission': TextEditingController(),
    'storeName': TextEditingController(),
    'storeLocation': TextEditingController(),
  };

  final List<Map<String, dynamic>> orders = [];
  final List<Map<String, String>> currentItems = [];
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController itemPriceController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _extractPhoneFromEmail();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _extractPhoneFromEmail() async {
    try {
      // Get user data from SharedPreferences (stored during login)
      final prefs = await SharedPreferences.getInstance();
      final storedPhone = prefs.getString('phone');

      extractedPhone = storedPhone ?? widget.phone;
      _loadStoreData();
    } catch (e) {
      extractedPhone = widget.phone;
      _loadStoreData();
    }
  }

  Future<void> _loadStoreData() async {
    try {
      // Get user data from SharedPreferences (stored during login)
      final prefs = await SharedPreferences.getInstance();

      final userName = prefs.getString('name') ?? 'غير محدد';
      final storeName = prefs.getString('store_name') ?? prefs.getString('name') ?? 'غير محدد';
      final userAddress = prefs.getString('address') ?? 'غير محدد';
      final userPhone =
          prefs.getString('phone') ?? extractedPhone ?? 'غير محدد';
      final userRole = prefs.getInt('role') ?? 0;
      final userId = prefs.getInt('user_id') ?? 0;
      final userEmail = prefs.getString('email') ?? '';
      final userImage = prefs.getString('image') ?? '';
      final isApproved = prefs.getBool('is_approved') ?? false;
      final isActive = prefs.getBool('is_active') ?? false;

      // Get the real commission percentage from SharedPreferences
      final commission = prefs.getDouble('commission_percentage') ?? 0.0;

      setState(() {
        storeData = {
          'id': userId,
          'name': userName,
          'store_name': storeName,
          'address': userAddress,
          'phone': userPhone,
          'email': userEmail,
          'image': userImage,
          'role': userRole,
          'appCommission': commission,
          'is_approved': isApproved,
          'is_active': isActive,
        };
        isLoading = false;
      });

      print('✅ تم تحميل بيانات المستخدم من SharedPreferences:');
      print('📱 الاسم: $userName');
      print('🏪 اسم المحل: $storeName');
      print('📍 العنوان: $userAddress');
      print('☎️ الهاتف: $userPhone');
      print(
        '👤 النوع: ${userRole == 0
            ? 'أدمن'
            : userRole == 1
            ? 'محل'
            : 'دليفري'}',
      );
      print('✅ مفعل: $isActive');
      print('✅ معتمد: $isApproved');
    } catch (e) {
      print('❌ خطأ في تحميل بيانات المستخدم: $e');
      setState(() {
        storeData = null;
        isLoading = false;
      });
    }
  }

  void addItemToCurrentOrder() {
    if (itemNameController.text.isNotEmpty &&
        itemPriceController.text.isNotEmpty) {
      setState(() {
        currentItems.add({
          'name': itemNameController.text,
          'price': itemPriceController.text,
        });
        itemNameController.clear();
        itemPriceController.clear();
      });
    }
  }

  // دالة لعرض الإشعار في الأعلى
  void _showTopNotification(String message, Color backgroundColor) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // تحديد الأيقونة حسب اللون
    IconData icon;
    if (backgroundColor == Colors.green) {
      icon = Icons.check_circle;
    } else if (backgroundColor == Colors.red) {
      icon = Icons.error;
    } else {
      icon = Icons.info;
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16, // تحت الـ status bar بمسافة مناسبة
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // إضافة الإشعار للـ overlay
    overlay.insert(overlayEntry);

    // إزالة الإشعار بعد 3 ثواني
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void addMoreOrders() {
    // جلب القيم من التيكست فيلد
    final client = controllers['client']!.text.trim();
    final clientAddress = controllers['clientAddress']!.text.trim();
    final clientPhone = controllers['clientPhone']!.text.trim();
    final deliveryCostText = controllers['deliveryCost']!.text.trim();

    // التشيك على الحقول الأربعة بس - بدون رسالة خطأ
    if (client.isEmpty ||
        clientAddress.isEmpty ||
        clientPhone.isEmpty ||
        deliveryCostText.isEmpty) {
      return; // مجرد عدم إضافة الطلب بدون رسالة
    }

    // parse تكلفة التوصيل
    final deliveryCost = double.tryParse(deliveryCostText) ?? 0.0;

    // إنشاء رقم الطلب
    String generatedOrderId = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(4, 13);

    // حساب الإجماليات (لو حابب تسيبها زي ما هي حتى لو المنتجات متقفلة)
    final totalItemsPrice = _calculateTotalItemsPrice();
    final totalPrice = totalItemsPrice + deliveryCost;

    final order = {
      'orderId': generatedOrderId,
      'client': client,
      'clientAddress': clientAddress,
      'clientPhone': clientPhone,
      'deliveryCost': deliveryCost,
      'items': List<Map<String, String>>.from(currentItems),
      'totalItemsPrice': totalItemsPrice,
      'totalPrice': totalPrice,
    };

    setState(() {
      orders.add(order);
      for (var controller in controllers.values) {
        controller.clear();
      }
      currentItems.clear();
    });

    print(
      '📦 Added order ${order['orderId']} to batch (Total: ${orders.length} orders)',
    );

    // التمرير تلقائياً للأسفل لعرض الطلبات المضافة
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  double _calculateTotalItemsPrice() {
    return currentItems.fold(
      0.0,
      (sum, item) => sum + (double.tryParse(item['price'] ?? '0') ?? 0.0),
    );
  }

  Future<void> submitAllOrders() async {
    if (orders.isEmpty || storeData == null) {
      return; // عدم إرسال بدون رسالة خطأ
    }

    try {
      final orderService = OrderService();

      for (int i = 0; i < orders.length; i++) {
        final order = orders[i];

        // Calculate commission based on store commission percentage
        final commissionRate =
            (storeData!['appCommission'] as num?)?.toDouble() ?? 0.0;
        final totalPrice = (order['totalPrice'] as num?)?.toDouble() ?? 0.0;
        final appCommission = (totalPrice * commissionRate / 100);

        final orderData = {
          'customer_name': order['client'],
          'customer_phone': order['clientPhone'],
          'customer_address': order['clientAddress'],
          'delivery_fee': (order['deliveryCost'] as num?)?.toDouble() ?? 0.0,
          'total': totalPrice,
          'user_add_id': storeData!['id'], // Use actual user ID from store data
          'status': 0, // Default status for new orders
          'notes': 'طلب من التطبيق',
          'application_fee': appCommission,
        };

        print('📦 إرسال الطلب ${i + 1}: $orderData');

        final response = await orderService.createOrder(orderData);

        if (response.statusCode == 201 || response.statusCode == 200) {
          print('✅ تم إرسال الطلب  بنجاح');
        } else {
          throw Exception(
            'فشل في إرسال الطلب ${i + 1}: ${response.statusCode}',
          );
        }
      }

      setState(() {
        orders.clear();
        for (var controller in controllers.values) {
          controller.clear();
        }
        currentItems.clear();
      });

      _showTopNotification(
        '✅ تم إرسال جميع الطلبات بنجاح! (${orders.length+1} طلب)',
        Colors.green,
      );
    } catch (e) {
      print('❌ خطأ في إرسال الطلبات: $e');
      _showTopNotification(
        '❌ فشل الإرسال: $e',
        Colors.red,
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
            backgroundColor: Colors.blue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'إضافة أوردر جديد',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (storeData == null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.blue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'إضافة أوردر جديد',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'لم يتم العثور على بيانات المحل',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'يرجى التواصل مع الإدارة لحل هذه المشكلة',
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'إضافة أوردر جديد',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadStoreData,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                controller: _scrollController,
                children: [
                  // Store Info Section
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF8F9FA),
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with icon and title
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF4A90E2),
                                  const Color(0xFF357ABD),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.store,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'معلومات المحل',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Store information in a grid layout
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  'اسم المحل',
                                  storeData?['store_name'] ?? 'غير محدد',
                                  Icons.store_outlined,
                                  const Color(0xFF28A745),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  'رقم الهاتف',
                                  extractedPhone ?? 'غير محدد',
                                  Icons.phone_outlined,
                                  const Color(0xFF17A2B8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          if (storeData!['role'] == 2) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    'العنوان',
                                    storeData?['address'] ?? 'غير محدد',
                                    Icons.location_on_outlined,
                                    const Color(0xFFFF6B35),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInfoCard(
                                    'نسبة التطبيق',
                                    "${(storeData?['appCommission'] ?? 0).toStringAsFixed(0)}%",
                                    Icons.percent_outlined,
                                    const Color(0xFF6F42C1),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    'نسبة التطبيق',
                                    "${(storeData?['appCommission'] ?? 0).toStringAsFixed(0)}%",
                                    Icons.percent_outlined,
                                    const Color(0xFF6F42C1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Container()), // Empty space for alignment
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order Details Section
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          const Color(0xFFFAFBFC),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with icon and title
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF28A745),
                                  const Color(0xFF20A039),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'تفاصيل الطلب',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Form fields in a clean layout
                          _buildFormField(
                            controller: controllers['client']!,
                            label: 'اسم العميل',
                            icon: Icons.person_outline,
                            color: const Color(0xFF6C5CE7),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildFormField(
                            controller: controllers['clientAddress']!,
                            label: 'عنوان العميل',
                            icon: Icons.location_on_outlined,
                            color: const Color(0xFFFF6B35),
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildFormField(
                                  controller: controllers['clientPhone']!,
                                  label: 'هاتف العميل',
                                  icon: Icons.phone_outlined,
                                  color: const Color(0xFF17A2B8),
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFormField(
                                  controller: controllers['deliveryCost']!,
                                  label: 'تكلفة التوصيل',
                                  icon: Icons.attach_money_outlined,
                                  color: const Color(0xFFE67E22),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Items Section
                  /* Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المنتجات',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: itemNameController,
                                  decoration: customInputDecoration(
                                    'اسم المنتج',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: itemPriceController,
                                  keyboardType: TextInputType.number,
                                  decoration: customInputDecoration('السعر'),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Colors.green,
                                ),
                                onPressed: addItemToCurrentOrder,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (currentItems.isNotEmpty) ...[
                            const Text(
                              'المنتجات المضافة:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            ...currentItems.map(
                              (item) => ListTile(
                                title: Text(item['name']!),
                                trailing: Text('${item['price']} جنيه'),
                                leading: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      currentItems.remove(item);
                                    });
                                  },
                                ),
                              ),
                            ),
                            const Divider(),
                            Text(
                              'إجمالي المنتجات: ${_calculateTotalItemsPrice().toStringAsFixed(2)} جنيه',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),*/
                  const SizedBox(height: 16),

                  // Add Order Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF6B35),
                          const Color(0xFFE55A2B),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: addMoreOrders,
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      label: const Text(
                        'إضافة طلب جديد',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Orders Summary
                  if (orders.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'الطلبات المضافة (${orders.length})',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${orders.length} طلب',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...orders.asMap().entries.map((entry) {
                              final index = entry.key;
                              final order = entry.value;
                              return ListTile(
                                title: Text(
                                  'طلب ${index + 1}: ${order['orderId']}',
                                ),
                                subtitle: Text('العميل: ${order['client']}'),
                                trailing: Text(
                                  '${(order['totalPrice'] ?? 0.0).toStringAsFixed(2)} جنيه',
                                ),
                                leading: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      orders.removeAt(index);
                                    });
                                  },
                                ),
                              );
                            }),
                            const Divider(),
                            Text(
                              'إجمالي جميع الطلبات: ${orders.fold(0.0, (sum, order) => sum + (order['totalPrice'] ?? 0.0)).toStringAsFixed(2)} جنيه',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit All Orders Button
                  if (orders.isNotEmpty)
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF28A745),
                            const Color(0xFF20A039),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF28A745).withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: submitAllOrders,
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        label: Text(
                          'إرسال جميع الطلبات (${orders.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
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

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade800,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: color,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
      ),
    );
  }

  InputDecoration customInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    );
  }
}
