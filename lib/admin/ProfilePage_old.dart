import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/Auth/token_storage.dart';
import 'SupportPage.dart';
import 'ChangePasswordPage.dart';

class ProfilePage extends StatefulWidget {
  final String phone;
  const ProfilePage({super.key, required this.phone});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      // Get user data from SharedPreferences (stored during login)
      final prefs = await SharedPreferences.getInstance();
      
      final userName = prefs.getString('name') ?? 'غير محدد';
      final userAddress = prefs.getString('address') ?? 'غير محدد';
      final userPhone = prefs.getString('phone') ?? widget.phone;
      final userRole = prefs.getInt('role') ?? 0;
      final userId = prefs.getInt('user_id') ?? 0;
      final userEmail = prefs.getString('email') ?? '';
      final userImage = prefs.getString('image') ?? '';
      final isApproved = prefs.getBool('is_approved') ?? false;
      final isActive = prefs.getBool('is_active') ?? false;

      setState(() {
        userData = {
          'id': userId,
          'name': userName,
          'address': userAddress,
          'phone': userPhone,
          'email': userEmail,
          'image': userImage,
          'role': userRole,
          'is_approved': isApproved,
          'is_active': isActive,
        };
        isLoading = false;
      });

      print('✅ تم تحميل بيانات المستخدم من SharedPreferences:');
      print('📱 الاسم: $userName');
      print('📍 العنوان: $userAddress');
      print('☎️ الهاتف: $userPhone');
      print('👤 النوع: ${userRole == 0 ? 'أدمن' : userRole == 1 ? 'محل' : 'دليفري'}');
      print('✅ مفعل: $isActive');
      print('✅ معتمد: $isApproved');
      
    } catch (e) {
      print('❌ خطأ في تحميل بيانات المستخدم: $e');
      setState(() {
        userData = null;
        isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // Clear token and preferences
      await TokenStorage.clearToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Navigate to login screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تسجيل الخروج: $e')),
      );
    }
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد حذف الحساب'),
        content: const Text('هل أنت متأكد أنك تريد حذف حسابك نهائيًا؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show confirmation that account deletion is not implemented yet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ميزة حذف الحساب غير متوفرة حالياً'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('نعم، احذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'الملف الشخصي',
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : userData == null
                  ? const Center(child: Text('خطأ في تحميل البيانات'))
                  : Column(
                      children: [
                        // User Avatar with Role Icon
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: userData!['image'] != null && userData!['image'].isNotEmpty
                                  ? NetworkImage(userData!['image'])
                                  : const AssetImage('assets/delivery_logo.jpeg') as ImageProvider,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: userData!['role'] == 0 ? Colors.purple :
                                         userData!['role'] == 1 ? Colors.blue :
                                         Colors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  userData!['role'] == 0 ? Icons.admin_panel_settings :
                                  userData!['role'] == 1 ? Icons.store :
                                  Icons.delivery_dining,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // User Name with Role Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              userData!['name'] ?? 'غير محدد',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
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
                        const SizedBox(height: 8),
                        
                        // User Status Indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: userData!['is_active'] ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    userData!['is_active'] ? Icons.check_circle : Icons.cancel,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    userData!['is_active'] ? 'مفعل' : 'غير مفعل',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: userData!['is_approved'] ? Colors.blue : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    userData!['is_approved'] ? Icons.verified : Icons.pending,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    userData!['is_approved'] ? 'معتمد' : 'في الانتظار',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        // User Details Card
                        const SizedBox(height: 16),
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildInfoRow(Icons.phone, 'الهاتف', userData!['phone'] ?? 'غير محدد'),
                                const Divider(),
                                _buildInfoRow(Icons.email, 'البريد الإلكتروني', userData!['email'] ?? 'غير محدد'),
                                const Divider(),
                                _buildInfoRow(Icons.location_on, 'العنوان', userData!['address'] ?? 'غير محدد'),
                                const Divider(),
                                _buildInfoRow(Icons.badge, 'رقم المستخدم', userData!['id'].toString()),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                child: ListView.separated(
                  itemCount: 4,
                  separatorBuilder:
                      (context, index) => const Divider(
                        thickness: 1,
                        color: Colors.grey,
                        indent: 16,
                        endIndent: 16,
                      ),
                  itemBuilder: (context, index) {
                    switch (index) {
                      case 0:
                        return ListTile(
                          leading: const Icon(Icons.lock),
                          title: const Text('تغيير كلمة المرور'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordPage(),
                              ),
                            );
                          },
                        );
                      case 1:
                        return ListTile(
                          leading: const Icon(Icons.message),
                          title: const Text('الدعم'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SupportPage(),
                              ),
                            );
                          },
                        );
                      case 2:
                        return ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('تسجيل الخروج'),
                          onTap: () => _logout(context),
                        );
                      case 3:
                        return ListTile(
                          leading: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                          title: const Text(
                            'حذف الحساب',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () => _confirmDeleteAccount(context),
                        );
                      default:
                        return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}