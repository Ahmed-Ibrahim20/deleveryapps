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

  @override
  void initState() {
    super.initState();
    _extractPhoneFromEmail();
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

  void addMoreOrders() {
    // جلب القيم من التيكست فيلد
    final client = controllers['client']!.text.trim();
    final clientAddress = controllers['clientAddress']!.text.trim();
    final clientPhone = controllers['clientPhone']!.text.trim();
    final deliveryCostText = controllers['deliveryCost']!.text.trim();

    // التشيك على الحقول الأربعة بس
    if (client.isEmpty ||
        clientAddress.isEmpty ||
        clientPhone.isEmpty ||
        deliveryCostText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى إدخال اسم العميل، العنوان، الهاتف، وتكلفة التوصيل',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ تم إضافة الطلب بنجاح! (${orders.length} طلب جاهز للإرسال)',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  double _calculateTotalItemsPrice() {
    return currentItems.fold(
      0.0,
      (sum, item) => sum + (double.tryParse(item['price'] ?? '0') ?? 0.0),
    );
  }

  Future<void> submitAllOrders() async {
    if (orders.isEmpty || storeData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد طلبات أو بيانات المتجر غير صالحة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
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
          print('✅ تم إرسال الطلب ${i + 1} بنجاح');
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ تم إرسال جميع الطلبات بنجاح! (${orders.length} طلب)',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ خطأ في إرسال الطلبات: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ فشل الإرسال: $e'),
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
                children: [
                  // Store Info Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                storeData!['role'] == 0
                                    ? Icons.admin_panel_settings
                                    : storeData!['role'] == 1
                                    ? Icons.store
                                    : Icons.delivery_dining,
                                color: Colors.blue,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                storeData!['role'] == 0
                                    ? 'معلومات الأدمن'
                                    : storeData!['role'] == 1
                                    ? 'معلومات المحل'
                                    : 'معلومات الدليفري',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: TextEditingController(
                              text: storeData?['name'] ?? 'غير محدد',
                            ),
                            readOnly: true,
                            decoration: customInputDecoration(
                              storeData!['role'] == 0
                                  ? 'اسم الأدمن'
                                  : storeData!['role'] == 1
                                  ? 'اسم المحل'
                                  : 'اسم الدليفري',
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (storeData!['role'] == 2) // Show address only for shops
                            TextFormField(
                              controller: TextEditingController(
                                text: storeData?['address'] ?? 'غير محدد',
                              ),
                              readOnly: true,
                              decoration: customInputDecoration('العنوان'),
                            ),
                          if (storeData!['role'] == 2) const SizedBox(height: 10),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: TextEditingController(
                              text: extractedPhone ?? 'غير محدد',
                            ),
                            readOnly: true,
                            decoration: customInputDecoration('رقم الهاتف'),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: TextEditingController(
                              text:
                                  "${(storeData?['appCommission'] ?? 0).toStringAsFixed(0)}%",
                            ),
                            readOnly: true,
                            decoration: customInputDecoration('نسبة التطبيق'),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order Details Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تفاصيل الطلب',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: controllers['client'],
                            decoration: customInputDecoration('اسم العميل'),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: controllers['clientAddress'],
                            decoration: customInputDecoration('عنوان العميل'),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: controllers['clientPhone'],
                            keyboardType: TextInputType.phone,
                            decoration: customInputDecoration('هاتف العميل'),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: controllers['deliveryCost'],
                            keyboardType: TextInputType.number,
                            decoration: customInputDecoration('تكلفة التوصيل'),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'مطلوب' : null,
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
                  ElevatedButton.icon(
                    onPressed: addMoreOrders,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة طلب'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                    ElevatedButton.icon(
                      onPressed: submitAllOrders,
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: Text(
                        'إرسال جميع الطلبات (${orders.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
