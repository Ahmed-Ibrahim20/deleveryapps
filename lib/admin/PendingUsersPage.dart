import 'package:flutter/material.dart';
import '../services/Api/user_service.dart';

class PendingUsersPage extends StatefulWidget {
  const PendingUsersPage({super.key});

  @override
  State<PendingUsersPage> createState() => _PendingUsersPageState();
}

class _PendingUsersPageState extends State<PendingUsersPage> {
  final UserService _userService = UserService();
  List<dynamic> pendingUsers = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
  }

  Future<void> _loadPendingUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await _userService.getPendingUsers();
      
      if (response.statusCode == 200) {
        final allUsers = response.data['data']['data'] ?? [];
        // فلترة المستخدمين الذين is_approved = false فقط
        final filteredUsers = allUsers.where((user) => user['is_approved'] == false).toList();
        
        setState(() {
          pendingUsers = filteredUsers;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'فشل في تحميل البيانات: ${response.statusMessage}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في الاتصال: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _approveUser(dynamic user) async {
    final userName = user['name'] ?? 'المستخدم';
    final userId = user['id'];
    
    String password = '';
    String confirmPassword = '';

    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('تسجيل الحساب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('إعداد كلمة مرور لـ $userName'),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onChanged: (value) => password = value.trim(),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onChanged: (value) => confirmPassword = value.trim(),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (password.isEmpty || confirmPassword.isEmpty) {
                  _showSnackBar('يرجى إدخال كلمة المرور وتأكيدها');
                  return;
                }
                if (password != confirmPassword) {
                  _showSnackBar('كلمة المرور وتأكيدها غير متطابقتان');
                  return;
                }
                if (password.length < 6) {
                  _showSnackBar('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (approved == true) {
      try {
        // أولاً: تغيير كلمة المرور
        final passwordResponse = await _userService.changeUserPassword(userId, password, confirmPassword);
        
        if (passwordResponse.statusCode == 200) {
          // ثانياً: اعتماد المستخدم
          final approveResponse = await _userService.approveUser(userId);
          
          if (approveResponse.statusCode == 200) {
            _showSnackBar('تم اعتماد $userName وإعداد كلمة المرور بنجاح', success: true);
            _loadPendingUsers(); // إعادة تحميل القائمة
          } else {
            _showSnackBar('تم إعداد كلمة المرور ولكن فشل في اعتماد المستخدم');
          }
        } else {
          _showSnackBar('فشل في إعداد كلمة المرور');
        }
      } catch (e) {
        _showSnackBar('خطأ في العملية: $e');
      }
    }
  }

  Future<void> _rejectUser(dynamic user) async {
    final userName = user['name'] ?? 'المستخدم';
    final userId = user['id'];
    
    // تأكيد الرفض
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الرفض'),
        content: Text('هل أنت متأكد من رفض طلب $userName؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('رفض', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _userService.rejectUser(userId);
        
        if (response.statusCode == 200) {
          _showSnackBar('تم رفض طلب $userName', success: true);
          _loadPendingUsers(); // إعادة تحميل القائمة
        } else {
          _showSnackBar('فشل في رفض الطلب');
        }
      } catch (e) {
        _showSnackBar('خطأ في رفض الطلب: $e');
      }
    }
  }

  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'طلبات فتح حساب',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await _loadPendingUsers();
          },
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            errorMessage!,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadPendingUsers,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    )
                  : pendingUsers.isEmpty
                      ? const Center(
                          child: Text(
                            "لا توجد طلبات حالياً",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: pendingUsers.length,
                          itemBuilder: (context, index) {
                            final user = pendingUsers[index];
                            return _buildUserCard(user);
                          },
                        ),
        ),
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    final String name = user['name'] ?? 'غير محدد';
    final String phone = user['phone'] ?? 'غير محدد';
    final int roleId = user['role'] ?? 0;
    final String role = roleId == 1 ? 'سائق' : roleId == 2 ? 'متجر' : 'أدمن';
    final String? storeName = user['store_name'];
    final String? category = user['catogrey']; // تصحيح الاسم من API
    final String? address = user['address'];
    final String? imageUrl = user['image'];
    final String? createdAt = user['created_at'];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.blue, width: 1.5),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (roleId != 2) // إخفاء الصورة للمتجر (role 2)
              CircleAvatar(
                radius: 40,
                backgroundImage: imageUrl != null
                    ? NetworkImage(imageUrl!)
                    : const AssetImage('assets/coding_developer.jpg')
                        as ImageProvider,
              ),
            if (roleId != 2) const SizedBox(height: 12),

            _buildRow(
              Icons.person,
              'اسم المستخدم:',
              name,
            ),
            _buildRow(
              Icons.storefront,
              'نوع الحساب:',
              role,
            ),
            if (storeName != null)
              _buildRow(
                Icons.home_work,
                'اسم المتجر:',
                storeName!,
              ),
            if (category != null)
              _buildRow(
                Icons.category,
                'التخصص:',
                category!,
              ),
            _buildRow(
              Icons.phone,
              'رقم الهاتف:',
              phone,
            ),
            if (roleId == 2) ...[
              _buildRow(
                Icons.location_on,
                'العنوان:',
                address ?? '---',
              ),
            ],
            if (createdAt != null)
              _buildRow(
                Icons.access_time,
                'بتاريخ التقديم:',
                createdAt!.split('T')[0],
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _approveUser(user),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('قبول'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _rejectUser(user),
                  icon: const Icon(Icons.cancel),
                  label: const Text('رفض'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}