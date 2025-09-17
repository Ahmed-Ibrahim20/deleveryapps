import 'package:flutter/material.dart';
import '../services/Api/complaint_service.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'الدعم الفني',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: const SupportTab(),
      ),
    );
  }
}

class SupportTab extends StatefulWidget {
  const SupportTab({super.key});

  @override
  State<SupportTab> createState() => _SupportTabState();
}

class _SupportTabState extends State<SupportTab> {
  final ComplaintService _complaintService = ComplaintService();
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _complaintService.getAllComplaints();
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['data'] != null && data['data']['data'] != null) {
          final complaintsData = List<Map<String, dynamic>>.from(data['data']['data']);
          
          setState(() {
            _complaints = complaintsData.map((complaint) {
              return {
                'id': complaint['id'],
                'name': complaint['user']['name'] ?? 'غير محدد',
                'phone': complaint['user']['phone'] ?? 'غير محدد',
                'message': complaint['complaint_text'] ?? 'لا توجد رسالة',
                'type': _getUserType(complaint['user']),
                'time': complaint['created_at'] ?? '',
                'status': complaint['status'] ?? 0,
              };
            }).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في جلب الشكاوى: $e")),
      );
    }
  }

  String _getUserType(Map<String, dynamic>? user) {
    if (user == null) return 'غير محدد';
    
    final role = user['role'];
    switch (role) {
      case 0:
        return 'أدمن';
      case 1:
        return 'سائق';
      case 2:
        return 'محل';
      default:
        return 'مستخدم';
    }
  }

  Future<void> _deleteComplaint(int complaintId, int index) async {
    try {
      final response = await _complaintService.deleteComplaint(complaintId);
      
      if (response.statusCode == 200) {
        setState(() {
          _complaints.removeAt(index);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ تم حذف الشكوى"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("فشل في حذف الشكوى"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("خطأ في حذف الشكوى: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_complaints.isEmpty) {
      return const Center(child: Text("لا توجد شكاوى حالياً"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _complaints.length,
      itemBuilder: (context, index) {
        final complaint = _complaints[index];
        final name = complaint['name'] ?? '---';
        final phone = complaint['phone'] ?? '---';
        final message = complaint['message'] ?? '---';
        final type = complaint['type'] ?? 'غير محدد';
        final time = complaint['time'] ?? '';
        final complaintId = complaint['id'];

        return Dismissible(
          key: Key(complaintId.toString()),
          direction: DismissDirection.horizontal,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("تأكيد الحذف"),
                content: const Text("هل أنت متأكد أنك تريد حذف هذه الشكوى؟"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("إلغاء"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("حذف", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) async {
            await _deleteComplaint(complaintId, index);
          },
          child: SupportMessageCard(
            name: name,
            type: type,
            message: message,
            phoneNumber: phone,
            time: time,
          ),
        );
      },
    );
  }
}

class SupportMessageCard extends StatelessWidget {
  final String name;
  final String type;
  final String message;
  final String phoneNumber;
  final String time;

  const SupportMessageCard({
    super.key,
    required this.name,
    required this.type,
    required this.message,
    required this.phoneNumber,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان العلوي
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: type == 'محل' ? Colors.green : Colors.orange,
                  child: Icon(
                    type == 'محل' ? Icons.store : Icons.delivery_dining,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'النوع: $type',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // الرسالة
            const Text(
              'نص الشكوى:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 16),

            // معلومات إضافية
         Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Icon(Icons.phone, size: 18, color: Colors.grey),
    const SizedBox(width: 6),
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          phoneNumber,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              time,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  ],
)

          ],
        ),
      ),
    );
  }
}