import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/Api/user_service.dart';
import 'HomePage.dart';

class AdminSignupScreen extends StatefulWidget {
  const AdminSignupScreen({super.key});

  @override
  State<AdminSignupScreen> createState() => _AdminSignupScreenState();
}

class _AdminSignupScreenState extends State<AdminSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final UserService _userService = UserService();
  bool _isLoading = false;

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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final password = _passwordController.text.trim();
      final passwordConfirmation = _confirmPasswordController.text.trim();

      try {
        final response = await _userService.createAdminUser(
          name: name,
          phone: phone,
          password: password,
          passwordConfirmation: passwordConfirmation,
          address: '', // تم إلغاء العنوان
          notes: '00', // تم إلغاء الملاحظات
          image: null, // تم إلغاء الصورة
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          _showSnackBar("تم إنشاء حساب الأدمن بنجاح", success: true);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          _showSnackBar("فشل في إنشاء الحساب: ${response.statusMessage}");
        }
      } catch (e) {
        if (e is DioException) {
          if (e.response != null) {
            final errorData = e.response?.data;
            if (errorData.toString().contains("phone")) {
              _showSnackBar("رقم الهاتف مستخدم بالفعل");
            } else {
              _showSnackBar("خطأ في الخادم: ${e.response?.statusMessage}");
            }
          } else {
            _showSnackBar("خطأ في الاتصال بالخادم");
          }
        } else {
          _showSnackBar("حدث خطأ: $e");
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text("تسجيل حساب أدمن"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.admin_panel_settings,
                    color: Colors.blue,
                    size: 30,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "لوحة تحكم الأدمن",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 🧾 النموذج
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: "الاسم الكامل",
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "الرجاء إدخال الاسم" : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: "رقم الهاتف",
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "الرجاء إدخال رقم الهاتف" : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: "كلمة المرور",
                      ),
                      validator: (value) => value!.length < 6
                          ? "كلمة المرور يجب أن تكون 6 أحرف على الأقل"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        labelText: "تأكيد كلمة المرور",
                      ),
                      validator: (value) => value != _passwordController.text
                          ? "كلمتا المرور غير متطابقتين"
                          : null,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "إنشاء حساب الأدمن",
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}