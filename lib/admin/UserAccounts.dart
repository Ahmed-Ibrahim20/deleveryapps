import 'package:flutter/material.dart';
import '../services/Api/user_service.dart';

class UserAccountsScreen extends StatefulWidget {
  const UserAccountsScreen({super.key});

  @override
  State<UserAccountsScreen> createState() => _UserAccountsScreenState();
}

class _UserAccountsScreenState extends State<UserAccountsScreen> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // جلب جميع المستخدمين من API
  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _userService.getAllUsers();
      
      if (response.statusCode == 200) {
        final data = response.data;
        print("📦 API Response: $data");
        
        if (data['data'] != null) {
          setState(() {
            List<Map<String, dynamic>> allUsers = [];
            
            // Handle nested pagination structure
            if (data['data'] is Map && data['data']['data'] is List) {
              // Paginated response: data.data.data[]
              allUsers = List<Map<String, dynamic>>.from(data['data']['data']);
            } else if (data['data'] is List) {
              // Direct array response
              allUsers = List<Map<String, dynamic>>.from(data['data']);
            } else if (data['data'] is Map) {
              // Single object response
              allUsers = [Map<String, dynamic>.from(data['data'])];
            }
            
            // Filter to show only approved users (is_approved: true)
            _users = allUsers.where((user) => user['is_approved'] == true).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _users = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar("خطأ في جلب البيانات: $e");
    }
  }

  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  // تحويل رقم الدور إلى نص عربي
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

  /// 🗑️ تأكيد الحذف
  void _confirmDelete(
    dynamic userId,
    String userName,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('هل أنت متأكد من حذف الحساب "$userName"؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteUser(userId);
                },
                child: const Text(
                  'نعم، احذف',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  ///  رفض وحذف حساب من API
  Future<void> _deleteUser(dynamic userId) async {
    try {
      final response = await _userService.rejectUser(userId);
      
      if (response.statusCode == 200) {
        _showSnackBar("تم  حذف الحساب بنجاح", success: true);
        _loadUsers(); // إعادة تحميل البيانات
      } else {
        _showSnackBar("فشل في حذف الحساب");
      }
    } catch (e) {
      _showSnackBar("حدث خطأ أثناء الحذف: $e");
    }
  }

  /// ✏️ تعديل كلمة المرور
 void _changePasswordDialog(String userId) {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('تعديل كلمة المرور'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'كلمة المرور الجديدة',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'تأكيد كلمة المرور',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () async {
            final newPassword = newPasswordController.text.trim();
            final confirmPassword = confirmPasswordController.text.trim();

            if (newPassword.isEmpty || newPassword.length < 6) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
                ),
              );
              return;
            }
            if (newPassword != confirmPassword) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('كلمتا المرور غير متطابقتين')),
              );
              return;
            }

            try {
              // استدعاء API لتغيير كلمة المرور
              final response = await _userService.changeUserPassword(
                userId,
                newPassword,
                confirmPassword,
              );

              Navigator.pop(context);
              if (response.statusCode == 200) {
                _showSnackBar("تم تحديث كلمة المرور بنجاح", success: true);
              } else {
                _showSnackBar("فشل في تحديث كلمة المرور");
              }
            } catch (e) {
              _showSnackBar("خطأ غير متوقع: $e");
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حسابات المستخدمين'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _users.isEmpty
                ? const Center(child: Text("لا يوجد حسابات حالياً"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final userId = user['id'];

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.blueAccent),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '👤 الاسم: ${user['name'] ?? 'غير محدد'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '📞 رقم الهاتف: ${user['phone'] ?? 'غير محدد'}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '📌 الدور: ${_getRoleText(user['role'])}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _confirmDelete(
                                      userId,
                                      user['name'] ?? 'غير محدد',
                                    ),
                                    icon: const Icon(
                                      Icons.delete_forever,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'حذف الحساب',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _changePasswordDialog(userId.toString()),
                                    icon: const Icon(Icons.edit, color: Colors.white),
                                    label: const Text(
                                      'تعديل كلمة السر',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}