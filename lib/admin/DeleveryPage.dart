import 'package:flutter/material.dart';
import '../services/Api/user_service.dart';
import 'UserPageDetails.dart';

class DeleveryPage extends StatefulWidget {
  const DeleveryPage({super.key});

  @override
  State<DeleveryPage> createState() => _DeleveryPageState();
}

class _DeleveryPageState extends State<DeleveryPage> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _filteredDrivers = [];
  bool _isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  // جلب السائقين من API (role = 1 و is_approved = true)
  Future<void> _loadDrivers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _userService.getAllUsers();
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['data'] != null) {
          List<Map<String, dynamic>> allUsers = [];
          
          // Handle nested pagination structure
          if (data['data'] is Map && data['data']['data'] is List) {
            allUsers = List<Map<String, dynamic>>.from(data['data']['data']);
          } else if (data['data'] is List) {
            allUsers = List<Map<String, dynamic>>.from(data['data']);
          }
          
          // Filter drivers: role = 1 AND is_approved = true
          final drivers = allUsers.where((user) => 
            user['role'] == 1 && user['is_approved'] == true
          ).toList();
          
          setState(() {
            _drivers = drivers;
            _filteredDrivers = drivers;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في جلب البيانات: $e")),
      );
    }
  }

  // فلترة السائقين حسب البحث
  void _filterDrivers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDrivers = _drivers;
      } else {
        _filteredDrivers = _drivers.where((driver) {
          final name = (driver['name'] ?? '').toString().toLowerCase();
          final phone = (driver['phone'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || phone.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        persistentFooterAlignment: AlignmentDirectional.center,
        appBar: AppBar(title: const Text('اختيار السائق')),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'ابحث باسم أو رقم الهاتف',
                  prefixIcon: Icon(Icons.search, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    borderSide: BorderSide(color: Colors.blue, width: 5.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                ),
                onChanged: (val) {
                  searchQuery = val.trim();
                  _filterDrivers(searchQuery);
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredDrivers.isEmpty
                        ? const Center(
                            child: Text(
                              "لا يوجد سائقين مطابقين للبحث",
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 9,
                            mainAxisSpacing: 8,
                            childAspectRatio: 3 / 3.2,
                            children: _filteredDrivers.map((driver) {
                              return Card(
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UserPageDetails(user: driver),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 40,
                                          backgroundImage: (driver['avatar'] != null && driver['avatar'].toString().isNotEmpty)
                                              ? NetworkImage(driver['avatar'])
                                              : const AssetImage('assets/deleveryphoto.jpeg') as ImageProvider,
                                          backgroundColor: Colors.transparent,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          driver['name'] ?? 'غير محدد',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          driver['phone'] ?? 'غير محدد',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 