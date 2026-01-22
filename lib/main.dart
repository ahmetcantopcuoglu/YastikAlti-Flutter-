import 'dart:io';
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'package:firebase_core/firebase_core.dart';


class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  // 1. Flutter motorunun hazır olduğundan emin ol
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Firebase'i başlat
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase başlatılamadı: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yastık Altı',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: HomePage(), // ❌ const KALDIRILDI
    );
  }
}
