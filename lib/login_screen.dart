import 'package:flutter/material.dart';
import 'package:my_app_delevery1/AccountNewRequestPage.dart';
import 'package:my_app_delevery1/admin/HomePage.dart';
import 'package:my_app_delevery1/delevery/home_delevery.dart';
import 'package:my_app_delevery1/store/home_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import './services/Auth/signin_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى إدخال البيانات كاملة")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await SigninService().post({
        "phone": phone,
        "password": password,
      });

      final data = response.data;
      if (data == null || data['token'] == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("خطأ في تسجيل الدخول")),
        );
        return;
      }

      //  حفظ البيانات في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setInt('role', data['role']);
      await prefs.setInt('user_id', data['user']['id'] ?? 0);
      await prefs.setString('name', data['user']['name'] ?? '');
      await prefs.setString('phone', data['user']['phone'] ?? '');
      await prefs.setString('email', data['user']['email'] ?? '');
      await prefs.setString('image', data['user']['image'] ?? '');
      await prefs.setString('address', data['user']['address'] ?? '');
      await prefs.setBool('is_approved', data['user']['is_approved'] ?? false);
      await prefs.setBool('is_active', data['user']['is_active'] ?? false);
      // حفظ نسبة العمولة مع التعامل مع أنواع البيانات المختلفة
      final commissionValue = data['user']['commission_percentage'];
      double commission = 0.0;
      if (commissionValue != null) {
        if (commissionValue is double) {
          commission = commissionValue;
        } else if (commissionValue is int) {
          commission = commissionValue.toDouble();
        } else if (commissionValue is String) {
          commission = double.tryParse(commissionValue) ?? 0.0;
        }
      }
      await prefs.setDouble('commission_percentage', commission);
      await prefs.setBool('hasLoggedOut', false);

      //  رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? "تم تسجيل الدخول بنجاح"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() => _isLoading = false);

      //  التوجيه حسب الدور
      final role = data['role'];
      if (role == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()), // أدمن
        );
      } else if (role == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DriverHomePage(phone: data['user']['phone'] ?? '')), // دليفري
        );
      } else if (role == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Home_shope(phone: data['user']['phone'] ?? '')), // محل
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("نوع حساب غير معروف")),
        );
      }
    } on DioException catch (e) {
      setState(() => _isLoading = false);
      
      // معالجة أخطاء API المحددة
      String errorMessage = "حدث خطأ غير متوقع";
      
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        
        // التحقق من وجود رسالة خطأ محددة
        if (responseData['message'] != null) {
          errorMessage = responseData['message'];
        }
        
        // التحقق من وجود أخطاء تفصيلية
        if (responseData['errors'] != null) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          List<String> errorMessages = [];
          
          errors.forEach((field, messages) {
            if (messages is List) {
              errorMessages.addAll(messages.cast<String>());
            }
          });
          
          if (errorMessages.isNotEmpty) {
            errorMessage = errorMessages.join('\n');
          }
        }
      } else if (e.type == DioExceptionType.connectionTimeout || 
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.connectionError) {
        errorMessage = "تحقق من اتصال الإنترنت";
      } else {
        errorMessage = "فشل في تسجيل الدخول";
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تحقق من اتصال الإنترنت"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: 80,
          title: const Text(
            "تسجيل الدخول",
            style: TextStyle(
              color: Colors.blue,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        resizeToAvoidBottomInset: false,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // محتوى الشاشة الأساسي
              Column(
                children: [
                  const SizedBox(height: 16),
                  const Icon(
                    Icons.delivery_dining,
                    size: 50,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "تطبيق رسلان لتوصيل الطلبات",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone, color: Colors.blue, size: 18),
                      SizedBox(width: 3),
                      Text(
                        " الدعم الفنى : 01008706489",
                        style: TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "أهلاً بعودتك!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: "رقم الهاتف",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "كلمة المرور",
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "تسجيل الدخول",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountNewRequestPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "ليس لديك حساب؟ تقديم طلب فتح حساب جديد",
                      style: TextStyle(color: Colors.blueAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),

              // بيانات الشركة بأسفل الشاشة
              Column(
                children: [
                  Image.asset('assets/coding.png', height: 100),
                  const SizedBox(height: 0),
                  const Text(
                    "تطوير وتصميم: شركة CODING DEVELOPER",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Times New Roman',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "شارع المرور - بنها - مصر",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "01025747690",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
