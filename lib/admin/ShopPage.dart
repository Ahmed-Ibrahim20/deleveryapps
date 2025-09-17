import 'package:flutter/material.dart';
import '../services/Api/user_service.dart';
import 'UserPageDetails.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _shops = [];
  List<Map<String, dynamic>> _filteredShops = [];
  bool _isLoading = true;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  // جلب المحلات من API (role = 2 و is_approved = true)
  Future<void> _loadShops() async {
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
          
          // Filter shops: role = 2 AND is_approved = true
          final shops = allUsers.where((user) => 
            user['role'] == 2 && user['is_approved'] == true
          ).toList();
          
          setState(() {
            _shops = shops;
            _filteredShops = shops;
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

  // فلترة المحلات حسب البحث
  void _filterShops(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredShops = _shops;
      } else {
        _filteredShops = _shops.where((shop) {
          final name = (shop['name'] ?? '').toString().toLowerCase();
          final phone = (shop['phone'] ?? '').toString().toLowerCase();
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
        appBar: AppBar(
          title: const Text(
            "قائمة المحلات",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'ابحث باسم المحل...',
                  prefixIcon: Icon(Icons.search, color: Colors.blue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                onChanged: (value) {
                  searchText = value;
                  _filterShops(searchText);
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredShops.isEmpty
                      ? const Center(
                          child: Text(
                            'لا يوجد متجر حتى الآن',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredShops.length,
                          itemBuilder: (context, index) {
                            final shop = _filteredShops[index];
                            return Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.store,
                                  color: Colors.blue,
                                ),
                                title: Text(
                                  shop['name'] ?? 'غير محدد',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                subtitle: Text(
                                  shop['phone'] ?? 'غير محدد',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserPageDetails(user: shop),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}