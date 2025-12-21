import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for persistence
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1366, 768),
      minimumSize: Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
     );

      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      }
    );
  }
    
  // 🛠️ FIX: Initialize Database Factory for Desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Load Language Preference
  final prefs = await SharedPreferences.getInstance();
  final String languageCode = prefs.getString('languageCode') ?? 'en';

  runApp(LiaqatStoreApp(initialLanguage: languageCode));
}

class LiaqatStoreApp extends StatefulWidget {
  final String initialLanguage;
  const LiaqatStoreApp({super.key, required this.initialLanguage});

  // Static method to allow language changing from anywhere
  static void setLocale(BuildContext context, Locale newLocale) {
    _LiaqatStoreAppState? state = context.findAncestorStateOfType<_LiaqatStoreAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<LiaqatStoreApp> createState() => _LiaqatStoreAppState();
}

class _LiaqatStoreAppState extends State<LiaqatStoreApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = Locale(widget.initialLanguage);
  }

  void setLocale(Locale locale) async {
    setState(() {
      _locale = locale;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liaqat Kiryana Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        fontFamily: _locale.languageCode == 'ur' ? 'NooriNastaleeq' : null, // Font Switch
      ),
      locale: _locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('ur', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}