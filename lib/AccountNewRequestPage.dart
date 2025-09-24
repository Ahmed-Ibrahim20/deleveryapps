// lib/features/auth/presentation/pages/account_new_request_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import 'package:my_app_delevery1/services/Auth/signup_service.dart';
import 'login_screen.dart'; // استبدل المسار لو ملف LoginScreen في مكان تاني

class AccountNewRequestPage extends StatefulWidget {
  const AccountNewRequestPage({super.key});

  @override
  State<AccountNewRequestPage> createState() => _AccountNewRequestPageState();
}

class _AccountNewRequestPageState extends State<AccountNewRequestPage> {
  String accountType = 'سائق';

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final storeNameController = TextEditingController();
  final categoryController = TextEditingController();

  File? _pickedImageFile;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("اختر مصدر الصورة"),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text("الكاميرا"),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            icon: const Icon(Icons.image),
            label: const Text("المعرض"),
          ),
        ],
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _pickedImageFile = File(pickedFile.path);
      });
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

 Future<void> _submitRequest() async {
  try {
    int role = accountType == "سائق" ? 1 : 2;

    // ✅ التحقق من المدخلات
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      _showSnackBar('من فضلك املى باقي البيانات');
      return;
    }

    // ✅ التحقق من صحة رقم الهاتف
    final phone = phoneController.text.trim();
    if (phone.length != 11 || !phone.startsWith("01")) {
      _showSnackBar('رقم الهاتف غير صحيح، يجب أن يكون 11 رقم ويبدأ بـ 01');
      return;
    }

    if (accountType == "سائق" && _pickedImageFile == null) {
      _showSnackBar('من فضلك اختر صورة شخصية');
      return;
    }

    if (accountType == "متجر") {
      if (storeNameController.text.isEmpty ||
          categoryController.text.isEmpty ||
          addressController.text.isEmpty) {
        _showSnackBar('من فضلك املى بيانات المتجر بالكامل');
        return;
      }
    }

    // ✅ تجهيز البيانات
    FormData formData = FormData.fromMap({
      "name": nameController.text,
      "phone": phoneController.text,
      "role": role,
      if (accountType == "متجر") ...{
        "store_name": storeNameController.text,
        "catogrey": categoryController.text,
        "address": addressController.text,
      },
      if (accountType == "سائق" && _pickedImageFile != null)
        "image": await MultipartFile.fromFile(
          _pickedImageFile!.path,
          filename: _pickedImageFile!.path.split("/").last,
        ),
    });

    final service = SignupService();
    final response = await service.post(formData);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (!mounted) return;
      _showSnackBar('تم إرسال الطلب بنجاح', success: true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      // ✅ لو السيرفر رجع استجابة خطأ
      final data = response.data;
      if (data != null && data.toString().contains("phone")) {
        _showSnackBar("الرقم دا مستخدم بالفعل، من فضلك ادخل رقم آخر");
      } else {
        _showSnackBar('فشل إرسال الطلب: ${response.statusMessage}');
      }
    }
  } catch (e) {
    // ✅ لو السيرفر رجع error من Dio
    if (e is DioError) {
      if (e.response != null) {
        final errorData = e.response?.data;

        // هنا بنشوف لو السيرفر بيرجع رسالة متعلقة بالهاتف
        if (errorData.toString().contains("phone")) {
          _showSnackBar("الرقم دا مستخدم بالفعل، من فضلك ادخل رقم آخر");
          return;
        }
      }
    }

    _showSnackBar('حصل خطأ: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text('طلب فتح حساب',
              style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Center(
                child: Text(
                  "تطبيق رسلان لتوصيل الطلبات",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
              ),
              const SizedBox(height: 24),
              const Text('نوع الحساب:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('سائق'),
                      value: 'سائق',
                      groupValue: accountType,
                      onChanged: (value) =>
                          setState(() => accountType = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('متجر'),
                      value: 'متجر',
                      groupValue: accountType,
                      onChanged: (value) =>
                          setState(() => accountType = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (accountType == 'سائق')
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey,
                        backgroundImage: _pickedImageFile != null
                            ? FileImage(_pickedImageFile!)
                            : null,
                        child: _pickedImageFile == null
                            ? const Icon(Icons.person,
                                size: 40, color: Colors.white)
                            : null,
                      ),
                      TextButton(
                        onPressed: _pickImage,
                        child:
                            const Text('اختيار صورة من الكاميرا أو المعرض'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              buildInputField(nameController, 'الاسم (الرجاء إدخال الاسم ثلاثي)'),
              buildInputField(
                  phoneController, 'رقم الهاتف', TextInputType.phone),
              if (accountType == 'متجر') ...[
                buildInputField(storeNameController, 'اسم المتجر'),
                buildInputField(categoryController, 'التخصص'),
                buildInputField(addressController, 'العنوان'),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submitRequest,
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('تقديم الطلب',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInputField(TextEditingController controller, String label,
      [TextInputType? type]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type ?? TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
