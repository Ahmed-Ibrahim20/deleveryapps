import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/Api/user_service.dart';

class UserPageDetails extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserPageDetails({super.key, required this.user});

  @override
  State<UserPageDetails> createState() => _UserPageDetailsState();
}

class _UserPageDetailsState extends State<UserPageDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();
  final TextEditingController _commissionController = TextEditingController();

  // User data variables
  String userName = '';
  String userPhone = '';
  String userEmail = '';
  String userAddress = '';
  String userRole = '';
  bool isActive = true;
  double commissionPercentage = 0.0;
  String userNotes = '';
  String userCategory = '';
  String createdAt = '';
  String updatedAt = '';

  // Statistics variables
  int completedOrders = 0;
  int inProgressOrders = 0;
  double totalDelivery = 0.0;
  double totalOrdersValue = 0.0; // للمحلات فقط
  double appPercentage = 0.0;
  double appCommission = 0.0;
  double netProfit = 0.0;
  bool isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    setState(() {
      userName = widget.user['name'] ?? 'غير محدد';
      userPhone = widget.user['phone'] ?? 'غير محدد';
      userEmail = widget.user['email'] ?? 'غير محدد';
      userAddress = widget.user['address'] ?? 'غير محدد';
      userRole = _getRoleText(widget.user['role']);
      isActive = widget.user['is_active'] ?? true;
      commissionPercentage = _parseDouble(widget.user['commission_percentage']);
      userNotes = widget.user['notes'] ?? 'لا توجد ملاحظات';
      userCategory = widget.user['category'] ?? 'غير محدد';
      createdAt = widget.user['created_at'] ?? 'غير محدد';
      updatedAt = widget.user['updated_at'] ?? 'غير محدد';

      _commissionController.text = commissionPercentage.toString();
    });
    
    // تحميل الإحصائيات من الـ API
    _loadStatistics();
  }

  // دالة جلب الإحصائيات من الـ API
  Future<void> _loadStatistics() async {
    setState(() {
      isLoadingStats = true;
    });

    try {
      final userId = widget.user['id'];
      final userRole = widget.user['role'];
      
      print('معرف المستخدم: $userId');
      print('دور المستخدم: $userRole');
      
      String endpoint;
      if (userRole == 1) {
        // سائق
        endpoint = 'http://127.0.0.1:8000/api/v1/dashboard/reports/delivery/$userId';
      } else if (userRole == 2) {
        // محل
        endpoint = 'http://127.0.0.1:8000/api/v1/dashboard/reports/shop/$userId';
      } else {
        // إذا لم يكن سائق أو محل، لا نحمل إحصائيات
        print('المستخدم ليس سائق أو محل');
        setState(() {
          isLoadingStats = false;
        });
        return;
      }
      
      print('رابط الـ API: $endpoint');

      // جلب التوكن من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        print('لا يوجد توكن');
        setState(() {
          isLoadingStats = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('رد الـ API: ${response.statusCode}');
      print('محتوى الرد: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == true && data['data'] != null) {
          final reportData = data['data'];
          
          setState(() {
            completedOrders = reportData['completed_orders_count'] ?? 0;
            appPercentage = _parseDouble(reportData['application_percentage']);
            appCommission = _parseDouble(reportData['application_commission']);
            netProfit = _parseDouble(reportData['net_profit']);
            
            if (userRole == 1) {
              // بيانات السائق
              totalDelivery = _parseDouble(reportData['total_delivery_fees']);
            } else if (userRole == 2) {
              // بيانات المحل
              totalOrdersValue = _parseDouble(reportData['total_orders_value']);
              totalDelivery = _parseDouble(reportData['total_delivery_fees']);
            }
          });
          print('تم تحديث البيانات بنجاح');
        } else {
          print('فشل في جلب البيانات: ${data['message'] ?? 'خطأ غير محدد'}');
        }
      } else {
        print('خطأ في الـ API: ${response.statusCode}');
        print('رسالة الخطأ: ${response.body}');
      }
    } catch (e) {
      print('خطأ في تحميل الإحصائيات: $e');
    } finally {
      setState(() {
        isLoadingStats = false;
      });
    }
  }

  // Helper methods for safe type conversion
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  String _getRoleText(dynamic role) {
    switch (role) {
      case 0:
        return 'أدمن';
      case 1:
        return 'سائق';
      case 2:
        return 'محل';
      default:
        return 'غير محدد';
    }
  }

  String _getPageTitle() {
    final role = widget.user['role'];
    switch (role) {
      case 1:
        return ' السائق: $userName';
      case 2:
        return ' متجر: $userName';
      default:
        return ' المستخدم: $userName';
    }
  }

  bool _isShop() {
    return widget.user['role'] == 2;
  }

  // Update user active status
  Future<void> _updateActiveStatus(bool newStatus) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('جاري تحديث حالة الحساب...'),
              ],
            ),
          );
        },
      );

      // Call API to update active status
      final response = await _userService.changeUserActiveStatus(
        widget.user['id'],
        newStatus,
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode == 200) {
        setState(() {
          isActive = newStatus;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? "تم تفعيل الحساب بنجاح"
                  : "تم إلغاء تفعيل الحساب بنجاح",
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("فشل في تحديث حالة الحساب"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(); // Close loading dialog if open
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("خطأ في تحديث حالة الحساب: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete user account functionality
  Future<void> _deleteUserAccount() async {
    try {
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('تأكيد حذف الحساب'),
            content: const Text(
              'هل أنت متأكد من حذف هذا الحساب نهائياً؟\n\nهذا الإجراء لا يمكن التراجع عنه.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'حذف نهائياً',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('جاري حذف الحساب...'),
                ],
              ),
            );
          },
        );

        final response = await _userService.rejectUser(widget.user['id']);
        Navigator.of(context).pop(); // Close loading dialog

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الحساب بنجاح'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(); // Go back to previous screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل في حذف الحساب'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حذف الحساب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update commission percentage
  Future<void> _updateCommission() async {
    final newCommission = double.tryParse(_commissionController.text);
    if (newCommission != null && newCommission >= 0 && newCommission <= 100) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('جاري تحديث نسبة العمولة...'),
                ],
              ),
            );
          },
        );

        // Call API to update commission
        final response = await _userService.changeUserCommission(
          widget.user['id'],
          newCommission,
        );

        Navigator.of(context).pop(); // Close loading dialog

        if (response.statusCode == 200) {
          setState(() {
            commissionPercentage = newCommission;
            appPercentage = newCommission;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "تم تحديث نسبة العمولة إلى ${newCommission.toStringAsFixed(2)}%",
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("فشل في تحديث نسبة العمولة"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop(); // Close loading dialog if open
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطأ في تحديث نسبة العمولة: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى إدخال نسبة صحيحة بين 0 و 100"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildUserDetailsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        shadowColor: Colors.blue.shade300,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User name
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    "الاسم: $userName",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Phone number
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text("رقم الهاتف: $userPhone", style: _detailTextStyle()),
                ],
              ),
              const SizedBox(height: 20),

              // Address (only for shops)
              if (_isShop()) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text("العنوان: $userAddress", style: _detailTextStyle()),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Category (only for shops)
              if (_isShop()) ...[
                Row(
                  children: [
                    const Icon(Icons.category, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text("التصنيف: $userCategory", style: _detailTextStyle()),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Commission percentage
              Row(
                children: [
                  const Icon(Icons.percent, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    "نسبة العمولة الحالية: ${commissionPercentage.toStringAsFixed(2)}%",
                    style: _detailTextStyle(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Commission input field
              TextField(
                controller: _commissionController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration("ادخل نسبة العمولة الجديدة (%)"),
              ),
              const SizedBox(height: 10),

              // Save commission button
              Center(
                child: ElevatedButton(
                  onPressed: _updateCommission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "حفظ النسبة",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Divider(height: 20, color: Colors.blueAccent, thickness: 1),

              // Active status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isActive ? "الحساب نشط" : "الحساب غير نشط",
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: isActive,
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                    onChanged: (value) async {
                      await _updateActiveStatus(value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Delete account button
              Center(
                child: ElevatedButton(
                  onPressed: _deleteUserAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "حذف الحساب نهائياً",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStatisticsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        shadowColor: Colors.blue.shade300,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.analytics, color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'ملخص الطلبات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Statistics Grid
              if (isLoadingStats)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (widget.user['role'] == 1 || widget.user['role'] == 2)
                Column(
                  children: [
                // إحصائيات السائقين والمحلات
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        '✅ الطلبات المكتملة',
                        completedOrders.toString(),
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        widget.user['role'] == 2 ? '💰 إجمالي قيمة الطلبات' : '💰 إجمالي رسوم التوصيل',
                        widget.user['role'] == 2 
                          ? '${totalOrdersValue.toStringAsFixed(2)} جنيه'
                          : '${totalDelivery.toStringAsFixed(2)} جنيه',
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.user['role'] == 2) // للمحلات فقط - عرض رسوم التوصيل أيضاً
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          '🚚 رسوم التوصيل',
                          '${totalDelivery.toStringAsFixed(2)} جنيه',
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatItem(
                          '💼 نسبة التطبيق',
                          '${appPercentage.toStringAsFixed(2)}%',
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                if (widget.user['role'] == 1) // للسائقين فقط
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          '💼 نسبة التطبيق',
                          '${appPercentage.toStringAsFixed(2)}%',
                          Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatItem(
                          '🧾 عمولة التطبيق',
                          '${appCommission.toStringAsFixed(2)} جنيه',
                          Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                if (widget.user['role'] == 2) // للمحلات فقط
                  const SizedBox(height: 16),
                if (widget.user['role'] == 2) // للمحلات فقط
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          '🧾 عمولة التطبيق',
                          '${appCommission.toStringAsFixed(2)} جنيه',
                          Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatItem(
                          '💵 صافي الربح',
                          '${netProfit.toStringAsFixed(2)} جنيه',
                          Colors.teal,
                        ),
                      ),
                    ],
                  ),
                if (widget.user['role'] == 1) // للسائقين فقط
                  const SizedBox(height: 16),
                if (widget.user['role'] == 1) // للسائقين فقط
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          '💵 صافي الربح',
                          '${netProfit.toStringAsFixed(2)} جنيه',
                          Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Container()),
                    ],
                  ),
                  ],
                )
              else
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'الإحصائيات متاحة للسائقين والمحلات فقط',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for styling
  TextStyle _detailTextStyle() {
    return const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4);
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.blueAccent),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getPageTitle()),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: 'التفاصيل'),
                Tab(text: 'الإحصائيات'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(child: buildUserDetailsCard()),
                  SingleChildScrollView(child: buildStatisticsCard()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
