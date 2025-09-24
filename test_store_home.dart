import 'package:flutter/material.dart';
import 'lib/store/home_store.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اختبار صفحة المتجر الرئيسية',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      home: Home_shope(phone: '01551721654'),
      debugShowCheckedModeBanner: false,
    );
  }
}
