import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/Api/complaint_service.dart';
import '../services/Auth/token_storage.dart';

class SupportShopeScreen extends StatefulWidget {
  const SupportShopeScreen({super.key});

  @override
  State<SupportShopeScreen> createState() => _SupportShopeScreenState();
}

class _SupportShopeScreenState extends State<SupportShopeScreen> {

  final ComplaintService _complaintService = ComplaintService();
  final TextEditingController _complaintController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  List<dynamic> complaints = [];
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isSubmitting = false;
  int currentPage = 0;
  bool showForm = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadComplaints();
  }

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final userName = prefs.getString('name') ?? 'غير محدد';
      final userPhone = prefs.getString('phone') ?? 'غير محدد';
      final userRole = prefs.getInt('role') ?? 0;
      final userId = prefs.getInt('user_id') ?? 0;

      setState(() {
        userData = {
          'id': userId,
          'name': userName,
          'phone': userPhone,
          'role': userRole,
        };
      });

      print('✅ تم تحميل بيانات المستخدم للدعم الفني:');
      print('📱 الاسم: $userName');
      print('☎️ الهاتف: $userPhone');
      print('🆔 معرف المستخدم: $userId');
      print('👤 النوع: ${userRole == 1 ? 'أدمن' : userRole == 2 ? 'محل' : 'دليفري'}');
      
      // التحقق من وجود التوكن
      final token = await TokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        print('🔐 التوكن موجود ومتاح للاستخدام');
      } else {
        print('⚠️ تحذير: لا يوجد توكن! قد تحتاج لتسجيل الدخول مرة أخرى');
      }
      
    } catch (e) {
      print('❌ خطأ في تحميل بيانات المستخدم: $e');
    }
  }

  Future<void> loadComplaints() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await _complaintService.getAllComplaints(page: currentPage + 1);
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        final complaintsData = responseData['data']['data'] ?? [];
        
        // فلترة الشكاوى بناءً على user_id المحفوظ في الـ storage
        List<dynamic> filteredComplaints = [];
        if (userData != null && userData!['id'] != null) {
          final currentUserId = userData!['id'];
          filteredComplaints = complaintsData.where((complaint) {
            return complaint['user_id'] == currentUserId;
          }).toList();
        } else {
          filteredComplaints = complaintsData;
        }
        
        print('✅ تم تحميل الشكاوى بنجاح: ${complaintsData.length} إجمالي، ${filteredComplaints.length} للمستخدم الحالي');
        
        setState(() {
          complaints = filteredComplaints;
          isLoading = false;
        });
      } else {
        throw Exception('فشل في تحميل الشكاوى');
      }
    } catch (e) {
      print('❌ خطأ في تحميل الشكاوى: $e');
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الشكاوى: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      setState(() {
        isSubmitting = true;
      });

      // إرسال الشكوى باستخدام API الحقيقي
      final complaintText = _complaintController.text.trim();
      final response = await _complaintService.createComplaint(complaintText);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ تم إرسال الشكوى بنجاح');
        
        _complaintController.clear();
        setState(() {
          showForm = false;
          isSubmitting = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال الشكوى بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // إعادة تحميل الشكاوى لعرض الشكوى الجديدة
        loadComplaints();
      } else {
        throw Exception('فشل في إرسال الشكوى - رمز الخطأ: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ خطأ في إرسال الشكوى: $e');
      setState(() {
        isSubmitting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال الشكوى: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getRoleText(int role) {
    switch (role) {
      case 1:
        return 'أدمن';
      case 2:
        return 'محل';
      case 3:
        return 'دليفري';
      default:
        return 'غير محدد';
    }
  }

  Color _getRoleColor(int role) {
    switch (role) {
      case 1:
        return Colors.purple;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final user = complaint['user'] ?? {};
    final userName = user['name'] ?? 'غير محدد';
    final userPhone = user['phone'] ?? '';
    final complaintText = complaint['complaint_text'] ?? 'لا يوجد نص';
    final createdAt = complaint['created_at'] ?? '';
    final status = complaint['status'] ?? 0;
    final adminNotes = complaint['admin_notes'];
    
    // تحويل التاريخ لصيغة أفضل
    String formattedDate = '';
    if (createdAt.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(createdAt);
        formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedDate = createdAt;
      }
    }
    
    // تحديد لون الحالة
    Color statusColor = Colors.orange;
    String statusText = 'قيد المراجعة';
    if (status == 1) {
      statusColor = Colors.green;
      statusText = 'تم الحل';
    } else if (status == 2) {
      statusColor = Colors.red;
      statusText = 'مرفوضة';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    userName.isNotEmpty ? userName[0] : '؟',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (userPhone.isNotEmpty)
                        Text(
                          userPhone,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      if (formattedDate.isNotEmpty)
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'نص الشكوى:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    complaintText,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (adminNotes != null && adminNotes.toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const Text(
                      'ملاحظات الإدارة:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adminNotes.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewComplaintForm() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_comment, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'شكوى جديدة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        showForm = false;
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // معلومات المستخدم
              if (userData != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'المرسل: ${userData!['name']} (${_getRoleText(userData!['role'])})',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // نص الشكوى
              TextFormField(
                controller: _complaintController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'اكتب شكواك هنا',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى كتابة نص الشكوى';
                  }
                  if (value.trim().length < 10) {
                    return 'يجب أن تكون الشكوى أكثر من 10 أحرف';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // زر الإرسال
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : submitComplaint,
                  icon: isSubmitting 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  label: Text(
                    isSubmitting ? 'جاري الإرسال...' : 'إرسال الشكوى',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الدعم الفني للمحل',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blueAccent,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              onPressed: loadComplaints,
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // زر إضافة شكوى جديدة
              if (!showForm)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        showForm = true;
                      });
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'إضافة شكوى جديدة',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // نموذج الشكوى الجديدة
              if (showForm) _buildNewComplaintForm(),
              
              // قائمة الشكاوى
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : complaints.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'لا توجد شكاوى حالياً',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: loadComplaints,
                            child: ListView.builder(
                              itemCount: complaints.length,
                              itemBuilder: (context, index) {
                                return _buildComplaintCard(complaints[index]);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // الحصول على headers مع التوكن
  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}