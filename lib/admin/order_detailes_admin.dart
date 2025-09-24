// import 'package:flutter/material.dart';

// class order_detailes_shope extends StatelessWidget {
//   final String phone;

//   const order_detailes_shope({super.key, required this.phone});

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(
//           centerTitle: true,
//           title: const Text(
//             'الطلبات الجارية',
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 18,
//             ),
//           ),
//           backgroundColor: Colors.blue.shade700,
//           elevation: 0,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(12),
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[50],
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: Colors.blue.shade300),
//                 ),
//                 child: const TextField(
//                   enabled: false,
//                   decoration: InputDecoration(
//                     hintText: 'ابحث برقم الطلب أو اسم العميل...',
//                     border: InputBorder.none,
//                     prefixIcon: Icon(Icons.search, color: Colors.blue.shade500),
//                     hintStyle: TextStyle(color: Colors.grey.shade500),
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 12),

//             Expanded(
//               child: ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: 2, // عدد الطلبات الثابتة
//                 itemBuilder: (context, index) {
//                   return _buildOrderCard(index);
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildOrderCard(int index) {
//     final isDeliveryUser = index == 0; // الأول للمتجر، الثاني للسائق
//     final orderStatus = index == 0 ? 1 : 2; // حالة الطلب

//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       clipBehavior: Clip.hardEdge,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Order Header
//           Container(
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.blue.shade50, Colors.blue.shade100],
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'طلب رقم ${index + 1}001',
//                   style: TextStyle(
//                     fontSize: 17,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.blue[800]!,
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 6,
//                   ),
//                   decoration: BoxDecoration(
//                     color: orderStatus == 1
//                         ? Colors.orange.shade500
//                         : Colors.green.shade500,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     orderStatus == 1 ? 'مقبول' : 'جاري التوصيل',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Store Info Section (For Delivery Users)
//           if (isDeliveryUser)
//             _buildCleanSection(
//               title: "معلومات المتجر",
//               color: Colors.blue.shade50,
//               borderColor: Colors.blue.shade100,
//               children: [
//                 _buildNamePhoneRow(
//                   'مطعم البيتزا المميز',
//                   '٠١٢٣٤٥٦٧٨٩',
//                 ),
//                 _buildAddressRow('شارع التحرير، الدقي، القاهرة'),
//               ],
//             ),

//           // Customer Info Section (Always shown)
//           _buildCleanSection(
//             title: "معلومات العميل",
//             color: Colors.green.shade50,
//             borderColor: Colors.green.shade100,
//             children: [
//               _buildNamePhoneRow(
//                 'أحمد محمد',
//                 '٠١٠٩٨٧٦٥٤٣٢',
//               ),
//               _buildAddressRow('مدينة نصر، عمارة ١٢، الدور الثالث'),
//             ],
//           ),

//           // Delivery Info Section (For Store Users)
//           if (!isDeliveryUser)
//             _buildCleanSection(
//               title: "معلومات السائق",
//               color: Colors.orange.shade50,
//               borderColor: Colors.orange.shade100,
//               children: [
//                 _buildNamePhoneRow(
//                   'محمد علي',
//                   '٠١١٢٣٤٥٦٧٨٩',
//                 ),
//               ],
//             ),

//           // Delivery Fee Section
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//             decoration: BoxDecoration(
//               color: Colors.orange.shade50,
//               border: Border(
//                 top: BorderSide(color: Colors.orange.shade200, width: 1),
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'رسوم التوصيل:',
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.orange,
//                   ),
//                 ),
//                 Text(
//                   '${index == 0 ? '25' : '30'} جنيه',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.orange.shade800,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Complete Delivery Button (For Delivery Users Only)
//           if (isDeliveryUser)
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               child: ElevatedButton(
//                 onPressed: null, // معطل في التصميم
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.grey[400],
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 2,
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.check_circle, size: 20),
//                     const SizedBox(width: 8),
//                     const Text(
//                       'إكمال التوصيل',
//                       style: TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCleanSection({
//     required String title,
//     required Color color,
//     required Color borderColor,
//     required List<Widget> children,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: color,
//         border: Border(
//           bottom: BorderSide(color: borderColor, width: 1),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               if (title == "معلومات المتجر") ...[
//                 Icon(Icons.store, size: 16, color: Colors.blue[800]!),
//                 const SizedBox(width: 6),
//               ] else if (title == "معلومات العميل") ...[
//                 Icon(Icons.person, size: 16, color: Colors.green[800]!),
//                 const SizedBox(width: 6),
//               ],
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.blue[800]!,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           ...children,
//         ],
//       ),
//     );
//   }

//   // عرض الاسم والهاتف في سطر واحد
//   Widget _buildNamePhoneRow(String name, String phone) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 3),
//       child: Row(
//         children: [
//           // الاسم مع label
//           Expanded(
//             flex: 3,
//             child: Row(
//               children: [
//                 Text(
//                   'الاسم: ',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//                 Expanded(
//                   child: Text(
//                     name,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 8),
//           // الهاتف مع label
//           Expanded(
//             flex: 2,
//             child: Row(
//               children: [
//                 Text(
//                   'هاتف: ',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.shade50,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: Colors.blue.shade200, width: 0.5),
//                     ),
//                     child: Text(
//                       phone,
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.blue.shade700,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // عرض العنوان مع label
//   Widget _buildAddressRow(String address) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         children: [
//           Text(
//             'العنوان: ',
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey.shade600,
//             ),
//           ),
//           Expanded(
//             child: Text(
//               address,
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey.shade700,
//                 fontWeight: FontWeight.w500,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }