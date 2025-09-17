import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/Auth/token_storage.dart';
import '../services/Api/user_service.dart';
import '../admin/ChangePasswordPage.dart';
import 'support_shope.dart';

class ProfilePage extends StatefulWidget {
  final String phone;
  const ProfilePage({super.key, required this.phone});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  final UserService _userService = UserService();

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
      print('👤 النوع: ${userRole ==1 ? 'أدمن' : userRole == 1 ? 'محل' : 'دليفري'}');
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
      print('🚪 بدء عملية تسجيل الخروج...');
      
      // Call logout API first
      final response = await _userService.logout();
      print('📡 استجابة API: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ تم تسجيل الخروج من الخادم بنجاح');
        
        // Clear token and preferences
        await TokenStorage.clearToken();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        print('🗑️ تم مسح البيانات المحلية');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل الخروج بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to login screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      } else {
        throw Exception('فشل في تسجيل الخروج من الخادم');
      }
    } catch (e) {
      print('❌ خطأ في تسجيل الخروج: $e');
      
      // Even if API fails, clear local data and logout
      await TokenStorage.clearToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل الخروج محلياً: $e'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // Navigate to login screen anyway
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    }
  }


  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.blueAccent,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
                                  color: userData!['role'] == 1 ? Colors.purple :
                                         userData!['role'] == 2 ? Colors.blue :
                                         Colors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  userData!['role'] == 1 ? Icons.admin_panel_settings :
                                  userData!['role'] == 2 ? Icons.store :
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
                                color: userData!['role'] ==1 ? Colors.purple :
                                       userData!['role'] == 2 ? Colors.blue :
                                       Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                userData!['role'] ==1 ? 'دليفري' :
                                userData!['role'] == 2 ? 'محل' :
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
                        
                        
                        // User Details Card
                        const SizedBox(height: 16),
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildInfoRow(Icons.phone, 'الهاتف', userData!['phone'] ?? 'غير محدد'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        Expanded(
                          child: ListView.separated(
                            itemCount: 3,
                            separatorBuilder: (context, index) => const Divider(
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
                                          builder: (_) => const SupportShopeScreen(),
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
