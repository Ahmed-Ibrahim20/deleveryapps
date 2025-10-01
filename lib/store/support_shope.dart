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
    Color statusColor = const Color(0xFFFF9800);
    String statusText = 'قيد المراجعة';
    IconData statusIcon = Icons.pending_outlined;
    
    if (status == 1) {
      statusColor = const Color(0xFF28A745);
      statusText = 'تم الحل';
      statusIcon = Icons.check_circle_outline;
    } else if (status == 2) {
      statusColor = const Color(0xFFDC3545);
      statusText = 'مرفوضة';
      statusIcon = Icons.cancel_outlined;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFFAFBFC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4A90E2).withOpacity(0.1),
                        const Color(0xFF357ABD).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4A90E2).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: const Color(0xFF4A90E2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (userPhone.isNotEmpty)
                        Text(
                          userPhone,
                          style: const TextStyle(
                            color: Color(0xFF6C757D),
                            fontSize: 12,
                          ),
                        ),
                      if (formattedDate.isNotEmpty)
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Color(0xFF6C757D),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor,
                        statusColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
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
            const SizedBox(height: 20),
            
            // Complaint text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF8F9FA),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE9ECEF),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90E2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.message_outlined,
                          color: Color(0xFF4A90E2),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'نص الشكوى:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF4A90E2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    complaintText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2C3E50),
                      height: 1.5,
                    ),
                  ),
                  
                  // Admin notes if available
                  if (adminNotes != null && adminNotes.toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF28A745).withOpacity(0.1),
                            const Color(0xFF20A039).withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF28A745).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF28A745).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings_outlined,
                                  color: Color(0xFF28A745),
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'ملاحظات الإدارة:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF28A745),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            adminNotes.toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF28A745),
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFFAFBFC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4A90E2),
                      Color(0xFF357ABD),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'شكوى جديدة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            showForm = false;
                          });
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // معلومات المستخدم
              if (userData != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                   
                  ),
                  child: Row(
                    children: [
                     
                      const SizedBox(width: 12),
                     
                    ],
                  ),
                ),
              ],
              
              // نص الشكوى
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4A90E2).withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A90E2).withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _complaintController,
                  maxLines: 6,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2C3E50),
                  ),
                  decoration: InputDecoration(
                    labelText: 'اكتب شكواك هنا بالتفصيل...',
                    labelStyle: TextStyle(
                      color: const Color(0xFF4A90E2),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF4A90E2),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(16),
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
              ),
              
              const SizedBox(height: 20),
              
              // زر الإرسال
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4A90E2),
                      const Color(0xFF357ABD),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A90E2).withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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
                      : Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                  label: Text(
                    isSubmitting ? 'جاري الإرسال...' : 'إرسال الشكوى',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

  String _getAppBarTitle() {
    if (userData == null) return 'الدعم الفني';
    
    final role = userData!['role'];
    final name = userData!['name'] ?? 'غير محدد';
    
    switch (role) {
      case 2:
        return 'الدعم الفني - $name';
      case 3:
        return 'الدعم الفني - $name';
      default:
        return 'الدعم الفني - $name';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true, // ✅ إصلاح مشكلة الكيبورد
        backgroundColor: const Color(0xFFF8F9FA), // خلفية مريحة للعين
        appBar: AppBar(
          title: Text(
            _getAppBarTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF4A90E2), // أزرق هادئ
          elevation: 2,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: loadComplaints,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'تحديث',
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView( // ✅ إصلاح مشكلة التمرير مع الكيبورد
            physics: const BouncingScrollPhysics(),
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          kToolbarHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // زر إضافة شكوى جديدة
                    if (!showForm)
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF28A745),
                              Color(0xFF20A039),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF28A745).withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              showForm = true;
                            });
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.add_comment_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          label: const Text(
                            'إضافة شكوى جديدة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // نموذج الشكوى الجديدة
                    if (showForm) _buildNewComplaintForm(),
                    
                    // قائمة الشكاوى
                    isLoading
                        ? Container(
                            height: 300,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF4A90E2),
                              ),
                            ),
                          )
                        : complaints.isEmpty
                            ? Container(
                                height: 300,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 64,
                                        color: Color(0xFF9E9E9E),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'لا توجد شكاوى حالياً',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Color(0xFF9E9E9E),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'اضغط على "إضافة شكوى جديدة" لبدء محادثة',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFFBDBDBD),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: loadComplaints,
                                color: const Color(0xFF4A90E2),
                                child: ListView.builder(
                                  shrinkWrap: true, // ✅ مهم لتجنب مشاكل التخطيط
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: complaints.length,
                                  itemBuilder: (context, index) {
                                    return _buildComplaintCard(complaints[index]);
                                  },
                                ),
                              ),
                  ],
                ),
              ),
            ),
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