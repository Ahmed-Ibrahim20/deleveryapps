import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:my_app_delevery1/login_screen.dart';
import 'providers/notification_provider.dart';

void main() {
  runApp(
    OverlaySupport.global(
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'تطبيق التوصيل',
        theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Amiri'),
        debugShowCheckedModeBanner: false,
        home: LoginScreen(),
      ),
    );
  }
}
