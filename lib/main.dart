// lib/main.dart - مکمل Fixed Version
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() {
  // ✅ CRITICAL: Desktop کے لیے sqflite_ffi initialize کریں
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Desktop platforms کے لیے
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(const LiaqatStoreApp());
}

class LiaqatStoreApp extends StatelessWidget {
  const LiaqatStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liaqat Kiryana Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto', // اردو کے لیے بہتر font
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}